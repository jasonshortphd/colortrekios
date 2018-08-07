import SpriteKit

class ScrollingBackground: SKSpriteNode
{
    var scrollingSpeed:CGFloat = 0
    
    // Generate the background images needed to scroll past view forever
    static func scrollingNodeWithImage( imageName image:String, containerWidth width:CGFloat) -> ScrollingBackground
    {
        let bgImage = UIImage(named: image)!
        
        let scrollNode = ScrollingBackground(color: UIColor.clear, size: CGSize(width: width, height: bgImage.size.height))
        
        scrollNode.scrollingSpeed = 1
        
        var totalWidthNeeded:CGFloat = 0
        
        // Append images to make sure we have the complete background
        while totalWidthNeeded < width + bgImage.size.width
        {
            let child = SKSpriteNode(imageNamed: image)
            child.anchorPoint = CGPoint.zero
            child.position = CGPoint(x: totalWidthNeeded, y: 0)
            scrollNode.addChild(child)
            totalWidthNeeded += child.size.width
        }
        
        return scrollNode
    }
    
    func update (currentTime:TimeInterval)
    {
        for child in self.children
        {
            child.position = CGPoint(x: child.position.x - self.scrollingSpeed, y: child.position.y)
            
            // Has the child scrolled off the screen?  Then we need to move it back to the far side to come back on screen again
            if( child.position.x <= -child.frame.size.width)
            {
                let delta = child.position.x + child.frame.size.width
                
                // Get the end of all the other children and move to that point
                child.position = CGPoint( x: child.frame.size.width * CGFloat(self.children.count - 1) + delta, y: child.position.y)
            }
        }
    }
}
