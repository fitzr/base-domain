
facade = require('../create-facade').create()

Facade = facade.constructor

{ AggregateRoot, Entity, BaseDict, LocalRepository } = facade.constructor


describe 'AggregateRoot', ->

    class Game extends AggregateRoot
        @properties:
            cards   : @TYPES.MODEL 'card-dict'
            players : @TYPES.MODEL 'player-dict'


    class Card extends Entity
        @properties:
            name: @TYPES.STRING

    class CardDict extends BaseDict
        @itemModelName: 'card'

    class CardRepository extends LocalRepository
        @modelName: 'card'
        @aggregateRoot: 'game'

    class Player extends Entity
        @properties:
            name: @TYPES.STRING

    class PlayerDict extends BaseDict
        @itemModelName: 'player'

    class PlayerRepository extends LocalRepository
        @modelName: 'player'
        @aggregateRoot: 'game'


    facade.addClass('game', Game)
    facade.addClass('card', Card)
    facade.addClass('card-dict', CardDict)
    facade.addClass('card-repository', CardRepository)
    facade.addClass('player', Player)
    facade.addClass('player-dict', PlayerDict)
    facade.addClass('player-repository', PlayerRepository)

    describe 'createModel', ->

        it 'set root to descendants', ->

            game = facade.createModel('game')
            card = game.createModel('card', name: 'road1')

            assert card.root is game
            assert game.root is facade



    describe 'createRepository', ->

        it 'saves to @memories', ->

            game = facade.createModel('game')
            card = game.createModel('card', name: 'road1')

            game.createRepository('card').save card

            assert Object.keys(game.memories).length is 1


    describe 'toPlainObject', ->

        it 'saves to @memories', ->

            game = facade.createModel('game')
            card = game.createModel('card', name: 'road1')

            game.createRepository('card').save card

            assert Object.keys(game.memories).length is 1

            plain = game.toPlainObject()

            expect(plain).to.eql
                cards:   ids: []
                players: ids: []
                memories:
                    card:
                        pool: '1': name: 'road1', id: '1'
                        currentIdNum: 1

