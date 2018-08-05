import SpriteKit
import GameplayKit

enum Enemies
{
    case small
    case medium
    case large
}

class GameScene: SKScene
{
    
    var tracksArray:[SKSpriteNode]? = [SKSpriteNode]()
    var player:SKSpriteNode?
    
    var currentTrack = 0
    var movingToTrack = false
    let maxTrack = 8
    
    let moveSound = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    
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
        let pulse = SKEmitterNode(fileNamed: "pulse")!
        player?.addChild(pulse)
        pulse.position = CGPoint(x: 0, y: 0)
        
    }
    
    func CreateEnemy( type:Enemies, forTrack track:Int) -> SKShapeNode?
    {
        let enemySprite = SKShapeNode()
        
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
     
        enemySprite.position.x = enemyPosition.x
        enemySprite.position.y = 50
        
        return enemySprite
    }
    
    override func didMove(to view: SKView)
    {
        setupTracks()
        createPlayer()
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
    
    func moveToNextTrack()
    {
        player?.removeAllActions()
        movingToTrack = true
        
        // Don't allow player to go off the screen
        if( currentTrack == maxTrack)
        {
            // TODO: Should play a different sound telling player they can't go any further
            return
        }
        
        guard let nextTrack = tracksArray?[currentTrack + 1].position else { return }
    
        if let player = self.player
        {
            // Move To: The next track location, let spritekit do the actual move
            let moveAction = SKAction.move(to: CGPoint(x: nextTrack.x, y:player.position.y), duration: 0.2)
            player.run(moveAction, completion:
            {
                // Upon completion - set the moving to false (keeps it clean)
                self.movingToTrack = false
            })
            currentTrack += 1
            
            // Play the sound at the scene level
            self.run(moveSound)
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
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
