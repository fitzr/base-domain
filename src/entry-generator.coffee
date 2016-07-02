fs = require 'fs'
Path = require 'path'
Path.isAbsolute ?= (str) -> str.charAt(0) is '/'
{ requireFile, camelize } = require './util'

Facade = require './main'
{ Base } = Facade
MasterDataResource = require './master-data-resource'


class ClassInfo
    constructor: (@name, @relPath, @className, @prefix) ->


class EntryGeneratorInput

    constructor: (facadePath, dirname, outfile) ->
        @validate(facadePath, dirname, outfile)

        @absDirname = @absolutePath(dirname)

        # public data
        @absOutfilePath = @absolutePath(outfile)
        @facadePath  = @relativePath(facadePath)
        @coreClasses = @getClassInfoList(@absDirname)
        @modules = @getModulesClasses()
        @masterJSONStr = JSON.stringify @getMasterJSON()
        @facadeClassName = requireFile(@absolutePath(facadePath)).name


    ###*
    @return {Array(ClassInfo)}
    ###
    getClassInfoList: (dirPath, prefix = '') ->

        relDirname = @relativePath(dirPath)

        for filename in @getClassFiles(dirPath)
            name = filename.split('.')[0]
            relPath = relDirname + '/' + name
            className = requireFile(Path.resolve dirPath, name).name
            new ClassInfo(name, relPath, className, prefix)


    ###*
    @return {{[string]: Array(ClassInfo)}}
    ###
    getModulesClasses: ->

        modules = {}

        for moduleName in @getModuleNames()
            modulePath = Path.join(@absDirname, moduleName)
            moduleNameCamelized = camelize(moduleName)
            modules[moduleName] = @getClassInfoList(modulePath, moduleNameCamelized)

        return modules


    ###*
    @method getMasterJSON
    @private
    @return {Object} master data
    ###
    getMasterJSON: ->

        allModules = {}
        for moduleName in @getModuleNames()
            allModules[moduleName] = Path.join(@absDirname, moduleName)

        try
            facade = Facade.createInstance
                dirname: @absDirname
                modules: allModules
                master: true

            { masterJSONPath } = facade.master

            return null if not fs.existsSync(masterJSONPath)

            return require(masterJSONPath)

        catch e
            return null


    ###*
    @return {Array(string)} array of module names
    ###
    getModuleNames: ->

        fs.readdirSync(@absDirname)
            .filter (subDirName) -> subDirName isnt 'master-data'
            .filter (subDirName) -> subDirName isnt 'custom-roles'
            .map (subDirname) => Path.join @absDirname, subDirname
            .filter (subDirPath) -> fs.statSync(subDirPath).isDirectory()
            .filter (subDirPath) ->
                fs.readdirSync(subDirPath).some (filename) ->
                    klass = requireFile Path.join(subDirPath, filename)
                    klass.isBaseDomainClass
            .map (subDirPath) -> Path.basename(subDirPath)


    ###*
    get domain files to load

    @method getClassFiles
    @private
    @return {Array(string)} filenames
    ###
    getClassFiles: (path) ->

        fileInfoDict = {}

        for filename in fs.readdirSync(path)

            [ name, ext ] = filename.split('.')
            continue if ext not in ['js', 'coffee']

            klass = requireFile path + '/' + filename

            fileInfoDict[name] = filename: filename, klass: klass

        files = []
        for name, fileInfo of fileInfoDict

            { klass, filename } = fileInfo
            continue if filename in files

            ParentClass = Object.getPrototypeOf(klass::).constructor

            if ParentClass.className and pntFileName = fileInfoDict[ParentClass.getName()]?.filename

                files.push pntFileName unless pntFileName in files

            files.push filename

        return files


    ###*
    validate input data
    ###
    validate: (facadePath, dirname, outfile) ->
        absFacadePath = @absolutePath facadePath
        absDirname = @absolutePath dirname
        outDir = Path.dirname(@absolutePath outfile)

        throw new Error("'#{absFacadePath}' is not found.") if not fs.existsSync(absFacadePath)
        throw new Error("dirname: '#{absDirname}' is not found.") if not fs.existsSync(absDirname)
        throw new Error("output directory: '#{outDir}' is not found.") if not fs.existsSync(outDir)


    absolutePath: (path) ->
        return Path.resolve(path) if Path.isAbsolute path
        return Path.resolve process.cwd(), path


    relativePath: (path) ->
        relPath = Path.relative(Path.dirname(@absOutfilePath), path)

        if relPath.charAt(0) isnt '.'
            relPath = './' + relPath

        return relPath



class EntryGenerator

    @generate: (facadePath, dirname, outfile, esCode = false) ->

        input = new EntryGeneratorInput(facadePath, dirname, outfile)

        if esCode
            generator = new ESCodeGenerator(input)
        else
            generator = new JSCodeGenerator(input)

        generator.generate()


    constructor: (@input) ->


    generate: ->

        code = [
            @getPragmas()
            @getImportStatements()
            @getPackedData()
            @getExportStatements()
        ].join('\n') + '\n'

        fs.writeFileSync(@input.absOutfilePath, code)

    getPragmas: -> ''


    getPackedData: ->

        { coreClasses, modules, masterJSONStr, facadeClassName } = @input

        """
        const packedData = {
            // eslint-disable-next-line quotes, key-spacing, object-curly-spacing, comma-spacing
            masterData : #{masterJSONStr},
            core: {
        #{@getPackedCode(coreClasses, 2)},
            },
            modules: {
        #{@getModulesPackedData(modules)}
            }
        }
        #{facadeClassName}.prototype.init = function init() { return this.initWithPacked(packedData) }
        """

    getPackedCode: (classes, indent) ->
        spaces = [0...indent * 4].map((x) -> ' ').join('')

        spaces + classes.map (classInfo) ->
            "'#{classInfo.name}': #{classInfo.prefix}#{classInfo.className}"
        .join(',\n' + spaces)


    getModulesPackedData: (modules) ->
        _ = '        '
        Object.keys(modules).map (modName) =>
            modClasses = modules[modName]
            """
            #{_}'#{modName}': {
            #{@getPackedCode(modClasses, 3)}
            #{_}}
            """
        .join(',\n')

class JSCodeGenerator extends EntryGenerator

    getPragmas: ->
        """
        /* eslint quote-props: 0, object-shorthand: 0, no-underscore-dangle: 0 */
        const __ = function __(m) { return m.default ? m.default : m }
        """

    getImportStatements: ->

        { coreClasses, modules, facadePath, facadeClassName } = @input

        # importing modules
        code = @getRequireStatement(facadeClassName, facadePath)
        code += @getRequireStatement(classInfo.className, classInfo.relPath) for classInfo in coreClasses
        for modName, modClasses of modules
            code += @getRequireStatement(classInfo.prefix + classInfo.className, classInfo.relPath) for classInfo in modClasses

        return code


    getExportStatements: ->

        { coreClasses, modules, facadeClassName } = @input

        classNames = coreClasses.map((coreClass) -> coreClass.className)
        for modName, modClasses of modules
            classNames = classNames.concat modClasses.map (modClass) -> modClass.prefix + modClass.className

        keyValues = classNames.map (className) ->
            "#{className}: #{className}"


        return """
        module.exports = {
            #{facadeClassName}: #{facadeClassName},
            #{keyValues.join(',\n    ')}
        }
        """

    getRequireStatement: (className, path) ->
        return "const #{className} = __(require('#{path}'))\n"



class ESCodeGenerator extends EntryGenerator

    getPragmas: ->
        """
        // @flow
        /* eslint quote-props: 0 */
        """


    getImportStatements: ->

        { coreClasses, modules, facadePath, facadeClassName } = @input

        code = @getImportStatement(facadeClassName, facadePath)
        code += @getImportStatement(classInfo.className, classInfo.relPath) for classInfo in coreClasses
        for modName, modClasses of modules
            code += @getImportStatement(classInfo.prefix + classInfo.className, classInfo.relPath) for classInfo in modClasses
        return code



    getExportStatements: ->

        { coreClasses, modules, facadeClassName } = @input

        classNames = coreClasses.map((coreClass) -> coreClass.className)
        for modName, modClasses of modules
            classNames = classNames.concat modClasses.map (modClass) -> modClass.prefix + modClass.className


        return """
        export default #{facadeClassName}
        export {
            #{facadeClassName},
            #{classNames.join(',\n    ')}
        }
        """

    ###*
    get import statement from className and path
    ###
    getImportStatement: (className, path) ->
        return "import #{className} from '#{path}'\n"


module.exports = EntryGenerator