GrayScott - Scream if you want to go Swifter
============================================

Non GPU GrayScott Reaction Diffusion Experiment Using &lt;s>NSOperation&lt;/s> Grand Central Dispatch in Swift

This is a fork from Simon Gladman's original as presented at Swift London in mid August. It changes the code from using NSOperation concurrency to GCD. It is also optimised over time and there are a series of blog posts the [Human Friendly Blog](http://blog.human-friendly.com/). It also adds an OS X build and greatly increases the size of the system calculated while getting better performance.

[Summary](http://blog.human-friendly.com/swift-optimisation-number-iosdevuk-swift-300) that has links to the detailed articles and also describes the branches [0](https://github.com/josephlord/GrayScott/tree/0) [1](https://github.com/josephlord/GrayScott/tree/1) [2](https://github.com/josephlord/GrayScott/tree/2) [fullSpeed](https://github.com/josephlord/GrayScott/tree/fullSpeed) that show the progression of the performance with the original size dataset and with similar performance measurement and logging for comparison purposes.

You can also look at the [network view](https://github.com/josephlord/GrayScott/network) to see that there were numerous false starts and failed experiments along the way (there were actually more than is shown).

I'm still carrying out more experiments to see if I can go further with the Accelerate framework and may look into GPU rendering. Suggestions and Pull requests welcome.
