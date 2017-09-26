//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Rob Percival on 22/08/2014.
//  Copyright (c) 2014 Appfish. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    var score = 0
    var scoreLabel = SKLabelNode()
    var startLabel = SKLabelNode()
    var gameOverLabel = SKLabelNode()

    var bird = SKSpriteNode()
    var bg = SKSpriteNode()
    var pipe1 = SKSpriteNode()
    var pipe2 = SKSpriteNode()
    var labelHolder = SKSpriteNode()

    let birdGroup:UInt32 = 1
    let objectGroup:UInt32 = 2
    let gapGroup:UInt32 = 0 << 3

    var gameOver = -1

    var movingObjects = SKNode()

    var madeItTooGap = false

    override func didMove(to view: SKView) {

        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)

        self.addChild(movingObjects)
        self.addChild(labelHolder)

        makeBackground()

        if gameOver == -1 {
            startLabel.fontName = "Helvetica"
            startLabel.fontSize = 30
            startLabel.text = "Tap to Start."
            startLabel.position = CGPoint(x: frame.midX, y: frame.midY)
            startLabel.zPosition = 10
            labelHolder.addChild(startLabel)
            return
        }
    }

    func gameSetup() {
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 60
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: frame.midX, y: self.frame.height - 70)
        scoreLabel.zPosition = 10
        self.addChild(scoreLabel)

        let birdTexture = SKTexture(imageNamed: "img/flappy1.png")
        let birdTexture2 = SKTexture(imageNamed: "img/flappy2.png")

        let animation = SKAction.animate(with: [birdTexture, birdTexture2], timePerFrame: 0.1)
        let makeBirdFlap = SKAction.repeatForever(animation)

        bird = SKSpriteNode(texture: birdTexture)
        bird.position = CGPoint(x: frame.midX, y: frame.midY)
        bird.run(makeBirdFlap)

        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdGroup
        bird.physicsBody?.contactTestBitMask = objectGroup
        bird.physicsBody?.collisionBitMask = gapGroup

        bird.zPosition = 10
        self.addChild(bird)

        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: 0)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = objectGroup
        self.addChild(ground)

        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(GameScene.makePipes), userInfo: nil, repeats: true)
    }

    func makeBackground() {
        let bgTexture = SKTexture(imageNamed: "img/bg.png")

        let movebg = SKAction.moveBy(x: -bgTexture.size().width*3, y: 0, duration: TimeInterval(0.1 * bgTexture.size().width * 3))
        let replacebg = SKAction.moveBy(x: bgTexture.size().width*3, y: 0, duration: 0)
        let movebgForever = SKAction.repeatForever(SKAction.sequence([movebg, replacebg]))

        for x in 0..<3 {

            let i = CGFloat(x)
            bg = SKSpriteNode(texture: bgTexture)
            bg.position = CGPoint(x: -bgTexture.size().width/2 + bgTexture.size().width * i, y: self.frame.midY)
            bg.size.height = self.frame.height
            bg.zPosition = -20

            bg.run(movebgForever)
            movingObjects.addChild(bg)
        }
    }

    func makePipes() {

        if gameOver > 0 {
            return
        }

        let gapHeight = 4 * bird.size.height
        let movementAmount = arc4random() % UInt32(frame.size.height / 2)
        let pipeOffset = CGFloat(movementAmount) - frame.size.height / 4
        let movePipes = SKAction.moveBy(x: -frame.width * 2, y: 0, duration: TimeInterval(frame.width / 100))
        let removePipes = SKAction.removeFromParent()
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])

        let pipe1Texture = SKTexture(imageNamed: "img/pipe1.png")
        pipe1 = SKSpriteNode(texture: pipe1Texture)
        pipe1.position = CGPoint(x: self.frame.midX + self.frame.size.width, y: self.frame.midY + pipe1.size.height / 2 + gapHeight / 2 + pipeOffset)
        pipe1.run(moveAndRemovePipes)
        pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipe1.size)
        pipe1.physicsBody?.isDynamic = false
        pipe1.physicsBody?.categoryBitMask = objectGroup
        movingObjects.addChild(pipe1)

        // bottom pipe
        let pipe2Texture = SKTexture(imageNamed: "img/pipe2.png")
        pipe2 = SKSpriteNode(texture: pipe2Texture)
        pipe2.position = CGPoint(x: frame.midX + frame.width, y: frame.midY - pipe2.size.height / 2 - gapHeight / 2 + pipeOffset)
        pipe2.run(moveAndRemovePipes)
        pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipe2.size)
        pipe2.physicsBody?.isDynamic = false
        pipe2.physicsBody?.categoryBitMask = objectGroup
        movingObjects.addChild(pipe2)

        let gap = SKNode()
        gap.position = CGPoint(x: self.frame.midX + self.frame.size.width, y: self.frame.midY + pipeOffset)
        gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipe1.size.width, height: gapHeight))
        gap.run(moveAndRemovePipes)
        gap.physicsBody?.isDynamic = false
        gap.physicsBody?.collisionBitMask = gapGroup
        gap.physicsBody?.categoryBitMask = gapGroup
        gap.physicsBody?.contactTestBitMask = birdGroup
        movingObjects.addChild(gap)

        madeItTooGap = false
    }

    func didBegin(_ contact: SKPhysicsContact) {

        if !madeItTooGap && (contact.bodyA.categoryBitMask == gapGroup || contact.bodyB.categoryBitMask == gapGroup) {
            madeItTooGap = true
            score += 1
            scoreLabel.text = "\(score)"
        } else if gameOver == 0 {
            gameOver = 1
            movingObjects.speed = 0

            gameOverLabel.fontName = "Helvetica"
            gameOverLabel.fontSize = 30
            gameOverLabel.text = "Game Over: Tap to play again."
            gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
            gameOverLabel.zPosition = 10
            labelHolder.addChild(gameOverLabel)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if gameOver == -1 {
            labelHolder.removeAllChildren()
            gameOver = 0
            gameSetup()
        } else if gameOver == 0 {
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
        } else {
            gameOver = 0
            score = 0
            scoreLabel.text = "0"
            movingObjects.removeAllChildren()
            makeBackground()
            bird.position = CGPoint(x: frame.midX, y: frame.midY)
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -50))
            labelHolder.removeAllChildren()

            movingObjects.speed = 1
        }
    }
}
