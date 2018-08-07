import SpriteKit

class StartScene: SKScene
{
    
    var playButton:SKSpriteNode?
    var gameScene:SKScene!
    var backgroundMusic: SKAudioNode!

    var scrollingBG:ScrollingBackground?
    
    override func didMove(to view: SKView)
    {
        playButton = self.childNode(withName: "startButton") as? SKSpriteNode
        
        // Add the infinite scrolling background
        scrollingBG = ScrollingBackground.scrollingNodeWithImage(imageName: "loopBG", containerWidth: self.size.width)
        scrollingBG?.scrollingSpeed = 1.5
        scrollingBG?.anchorPoint = .zero
        
        self.addChild(scrollingBG!)
        
        if let musicURL = Bundle.main.url(forResource: "MenuHighscoreMusic", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)
            
            if node == playButton
            {
                let transition = SKTransition.fade(withDuration: 2.5)
                
                gameScene = SKScene(fileNamed: "GameScene")
                gameScene.scaleMode = .aspectFit
                
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
    }
    
    // Update the scrolling background if we have one
    override func update (_ currentTime: TimeInterval)
    {
        if let scrollBG = self.scrollingBG
        {
            scrollBG.update(currentTime: currentTime)
        }
    }
}
