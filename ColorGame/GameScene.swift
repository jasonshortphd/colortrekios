import SpriteKit
import GameplayKit

enum Enemies:Int
{
    case small
    case medium
    case large
}

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var tracksArray:[SKSpriteNode]? = [SKSpriteNode]()
    var player:SKSpriteNode?
    var target:SKSpriteNode?
    
    // MARK: HUD / UX
    var timeLabel:SKLabelNode?
    var scoreLabel:SKLabelNode?
    var currentScore:Int = 0
    {
        // Compute the score again when it is set, so we can update the UI
        didSet
        {
            self.scoreLabel?.text = "SCORE: \(self.currentScore)"
        }
    }
    var remainingTime:TimeInterval = 60
    {
        didSet
        {
            self.timeLabel?.text = "TIME: \(Int(self.remainingTime))"
        }
    }
    
    // Initialize the HUD
    func createHUD()
    {
        timeLabel = self.childNode(withName: "time") as? SKLabelNode
        scoreLabel = self.childNode(withName: "score") as? SKLabelNode
        
        timeLabel?.fontColor = UIColor.white

        remainingTime = 60
        currentScore = 0
    }

    
    var currentTrack = 0
    var movingToTrack = false
    let maxTrack = 8

    // MARK: Sounds
    let moveSound = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    var backgroundAudio:SKAudioNode!

    // Choice of velocity per track chosen randomly at generation time
    let trackVelocities = [180, 200, 250]
    
    // Per track, are the enemies moving up or down?
    var directionArray = [Bool]()
    
    // Assigned velocity per track
    var velocityArray = [Int]()
    
    // MARK: Physics bitmasks
    let playerCategory:UInt32 = 0x01 << 0
    let enemyCategory:UInt32 = 0x01 << 1
    let targetCategory:UInt32 = 0x01 << 2
    let powerUpCategory:UInt32 = 0x01 << 3
    
    
    func setupTracks()
    {
        for i in 0 ... maxTrack
        {
            if let track = self.childNode(withName: "\(i)") as? SKSpriteNode {
                tracksArray?.append(track)
            }
        }
    }
    
    func createPlayer()
    {
        player = SKSpriteNode(imageNamed: "player")
        guard let playerPosition = tracksArray?.first?.position.x else {return}
        player?.position = CGPoint(x: playerPosition, y: self.size.height / 2)
        
        // Add the player to the child tree so it gets rendered
        self.addChild(player!)
        
        // We can also add emitters from particles the same way, but attach to the player as a child
        let pulse = SKEmitterNode(fileNamed: "pulse.sks")!
        player?.addChild(pulse)
        pulse.position = CGPoint(x: 0, y: 0)
        
        player?.physicsBody = SKPhysicsBody(circleOfRadius: player!.size.width / 2)
        player?.physicsBody?.linearDamping = 0
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = 0
        // Who do we want to be notified when we hit them?
        player?.physicsBody?.contactTestBitMask = enemyCategory | targetCategory | powerUpCategory
        
    }
    
    func createTarget()
    {
        // Find the target in the scene
        target = self.childNode(withName: "target") as? SKSpriteNode
        
        target?.physicsBody = SKPhysicsBody(circleOfRadius: target!.size.width / 2)
        target?.physicsBody?.categoryBitMask = targetCategory
        // We don't want the target to "collide" in a physics sense - we just want to get the collision notification
        target?.physicsBody?.collisionBitMask = 0
    }
    
    func createEnemy( type:Enemies, forTrack track:Int) -> SKShapeNode?
    {
        let enemySprite = SKShapeNode()
        enemySprite.name = "ENEMY"
        
        switch type
        {
        case .small:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y:0, width:20, height: 70), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor(red: 0.4431, green: 0.5529, blue: 0.7451, alpha: 1)
        case .medium:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y:0, width:20, height: 100), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor(red: 0.7804, green: 0.4039, blue: 0.4039, alpha: 1)
        case .large:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y:0, width:20, height: 130), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor(red: 0.7804, green: 0.6392, blue: 0.4039, alpha: 1)
        }
        
        // If we can't get a track yet return nil
        guard let enemyPosition = tracksArray?[track].position else { return nil }
     
        let up = directionArray[track]
        enemySprite.position.x = enemyPosition.x
        enemySprite.position.y = up ? -130 : self.size.height + 130
        
        // Add a physics body, set velocity +- depending upon the track direction
        enemySprite.physicsBody = SKPhysicsBody(edgeLoopFrom: enemySprite.path!)
        enemySprite.physicsBody?.velocity = up ? CGVector(dx: 0, dy: velocityArray[track]) : CGVector(dx: 0, dy: -velocityArray[track])
        enemySprite.physicsBody?.categoryBitMask = enemyCategory
        
        return enemySprite
    }
    
    func createPowerUp(forTrack track:Int)->SKSpriteNode?
    {
        let powerUpSprite = SKSpriteNode(imageNamed: "powerUp")
        
        powerUpSprite.physicsBody = SKPhysicsBody(circleOfRadius: powerUpSprite.size.width/2)
        powerUpSprite.physicsBody?.linearDamping = 0
        powerUpSprite.physicsBody?.collisionBitMask = 0 // No physics collisions
        powerUpSprite.physicsBody?.categoryBitMask = powerUpCategory
        // TODO: Fix this in the remove loop
        powerUpSprite.name = "ENEMY"
        let up = directionArray[track]
        
        guard let powerUpXPosition = tracksArray?[track].position.x else { return nil }
        
        powerUpSprite.position.x = powerUpXPosition
        
        powerUpSprite.position.y = up ? -130 : self.size.height + 130
        
        powerUpSprite.physicsBody?.velocity = up ? CGVector(dx: 0, dy: velocityArray[track]) :
                                                    CGVector(dx: 0, dy: -velocityArray[track])
        
        return powerUpSprite
    }
    
    func spawnEnemies()
    {
        var randomTrackNumber = 0
        let createPowerUp = GKRandomSource.sharedRandom().nextBool()
        
        if( createPowerUp )
        {
            randomTrackNumber = GKRandomSource.sharedRandom().nextInt(upperBound: 6)+1
            if let powerUpObject = self.createPowerUp(forTrack: randomTrackNumber)
            {
                self.addChild(powerUpObject)
            }
        }
        
        for i in 1 ... 7
        {
            if i == randomTrackNumber
            {
                continue
            }
            
            let randomEnemyType = Enemies(rawValue: GKRandomSource.sharedRandom().nextInt(upperBound: 3))!
            if let newEnemy = createEnemy(type: randomEnemyType, forTrack: i)
            {
                // Attach them to the scene
                self.addChild(newEnemy)
            }
        }
        
        self.enumerateChildNodes(withName: "ENEMY")
        {
            (node:SKNode, nil) in
            if node.position.y < -150 || node.position.y > self.size.height + 150
            {
                node.removeFromParent()
            }
        }
    }
    
    func nextLevel(playerPhyicsBody:SKPhysicsBody)
    {
        currentScore += 1
        self.run(SKAction.playSoundFileNamed("levelUp.wav", waitForCompletion: false))
        let emitter = SKEmitterNode(fileNamed: "fireworks.sks")

        playerPhyicsBody.node?.addChild(emitter!)

        self.run(SKAction.wait(forDuration: 0.5))
        {
            emitter!.removeFromParent()
            self.movePlayerToStart()
        }
    }
    
    func launchGameTimer ()
    {
        let timeAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run({self.remainingTime -= 1}),
            SKAction.wait(forDuration: 1)
        ]))
        
        timeLabel?.run(timeAction)
    }
    
    override func didMove(to view: SKView)
    {
        setupTracks()
        createHUD()
        createPlayer()
        createTarget()
        launchGameTimer()
        
        // Assign ourself to the contact delegate for the physicsWorld
        self.physicsWorld.contactDelegate = self
        
        if let musicURL = Bundle.main.url(forResource: "background", withExtension: "wav")
        {
            backgroundAudio = SKAudioNode(url: musicURL)
            addChild(backgroundAudio)
        }

        // Setup of the tracks
        if let numberOfTracks = tracksArray?.count
        {
            for _ in 0 ... numberOfTracks
            {
                let randomNumberForVelocity = GKRandomSource.sharedRandom().nextInt(upperBound: 3)
                velocityArray.append(trackVelocities[randomNumberForVelocity])
                directionArray.append( GKRandomSource.sharedRandom().nextBool())
            }
        }
        
        self.run(SKAction.repeatForever(SKAction.sequence(
            [
                SKAction.run {
                    self.spawnEnemies()
                },
                SKAction.wait(forDuration: 2)
            ])))
    }
    
    // Start the player moving up or down along its current position
    func moveVertically (up:Bool)
    {
        if up
        {
            let moveAction = SKAction.moveBy(x: 0, y: 3, duration: 0.01)
            let repeatAction = SKAction.repeatForever(moveAction)
            player?.run(repeatAction)
        }else{
            let moveAction = SKAction.moveBy(x: 0, y: -3, duration: 0.01)
            let repeatAction = SKAction.repeatForever(moveAction)
            player?.run(repeatAction)
        }
    }
    
    func movePlayerToStart()
    {
        if let player = self.player
        {
            player.removeFromParent()
            self.player = nil
            self.currentTrack = 0
            self.createPlayer()
        }
    }
    
    func moveToNextTrack()
    {
        player?.removeAllActions()
        movingToTrack = true
        
//        // Don't allow player to go off the screen
//        if( currentTrack == maxTrack)
//        {
//            // TODO: Should play a different sound telling player they can't go any further
//            return
//        }
        
        let targetTrack = currentTrack >= maxTrack ? currentTrack : currentTrack + 1
        
        guard let nextTrack = tracksArray?[targetTrack].position else { return }
    
        if let player = self.player
        {
            // Move To: The next track location, let spritekit do the actual move
            let moveAction = SKAction.move(to: CGPoint(x: nextTrack.x, y:player.position.y), duration: 0.2)
            
            let up = directionArray[targetTrack]
            
            
            player.run(moveAction, completion:
            {
                // Upon completion - set the moving to false (keeps it clean)
                self.movingToTrack = false
                
                if targetTrack != 8
                {
                    self.player?.physicsBody?.velocity = up ? CGVector(dx: 0, dy: self.velocityArray[targetTrack]) : CGVector(dx: 0, dy: -self.velocityArray[targetTrack])
                } else {
                    // Player on the last path, we want them to NOT be moving
                    self.player?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                }
                
            })
            currentTrack += 1
            
            // Play the sound at the scene level
            //self.run(moveSound)
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
            let location = touch.previousLocation(in: self)
            let node = self.nodes(at: location).first
            
            if node?.name == "right" || node?.name == "rightImg"
            {
               moveToNextTrack()
            } else if node?.name == "up" || node?.name == "upImg"
            {
                moveVertically(up: true)
            } else if node?.name == "down" || node?.name == "downImg"
            {
                moveVertically(up: false)
            }
        }
    }
    
    // Stop all actions on the player when touches are let up
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // Don't do this if the player is moving between tracks
        if !movingToTrack
        {
            player?.removeAllActions()
        }
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        player?.removeAllActions()
    }
    
    // MARK: Contact delegate
    func didBegin( _ contact: SKPhysicsContact)
    {
        var playerBody:SKPhysicsBody
        var otherBody:SKPhysicsBody
        
        // The smallest one is the player (0x01)
        if( contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
        {
            playerBody = contact.bodyA
            otherBody = contact.bodyB
        }
        else
        {
            playerBody = contact.bodyB
            otherBody = contact.bodyA
        }
        
        if playerBody.categoryBitMask == playerCategory && otherBody.categoryBitMask == enemyCategory
        {
            self.run(SKAction.playSoundFileNamed("fail.wav", waitForCompletion: true))
            movePlayerToStart()
        }
        else if playerBody.categoryBitMask == playerCategory && otherBody.categoryBitMask == targetCategory
        {
            nextLevel(playerPhyicsBody: playerBody)
        }
        else if playerBody.categoryBitMask == playerCategory && otherBody.categoryBitMask == powerUpCategory
        {
            self.run(SKAction.playSoundFileNamed("powerUp.wav", waitForCompletion: false))
            otherBody.node?.removeFromParent()
            remainingTime += 5
        }
    }
    
    // MARK: Frame update loop
    
    override func update(_ currentTime: TimeInterval)
    {
        // Might not have a player object yet...
        if let player = self.player
        {
            if player.position.y > self.size.height || player.position.y < 0
            {
                movePlayerToStart()
            }
        }
        
        if remainingTime <= 5
        {
            timeLabel?.fontColor = UIColor.red
        }
        
        if remainingTime <= 0
        {
            gameOver()
        }
    }
    
    func gameOver()
    {
        self.run(SKAction.playSoundFileNamed("levelCompleted.wav", waitForCompletion: false))
        
        let transition = SKTransition.fade(withDuration: 1.5)
        
        if let gameOverScene = SKScene(fileNamed: "GameOverScene")
        {
            gameOverScene.scaleMode = .aspectFit
            self.view?.presentScene(gameOverScene, transition: transition)
        }
        
        
    }
}
