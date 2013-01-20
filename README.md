# IIIThumbFlow #
***
### Summary ###
IIIThumbFlow is a simple **iOS** view component for presenting images in a vertical flow style. It supports both local and web images. It's optimized in various aspects, you can load unlimited images in IIIThumbFlow.

<img width=200 src="https://github.com/sehone/IIIThumbFlow/raw/master/Screenshots/1_flow.png"/> &nbsp;&nbsp;&nbsp;<img width=200 src="https://github.com/sehone/IIIThumbFlow/raw/master/Screenshots/2_detail.png"/>

### Optimization ###
1. Reuse cells (like UITableView).
2. Cache images (both memory and disk layers).
3. Use thumbs instead of original images.

### Other features ###
1. Change data source for images dynamically.
2. Set number of columns dynamically.
3. Reload images at the end of user dragging, instead of decelerating.
4. Return index of tapped image.

### How to use it ###
1. Link binary with libraries: `MapKit.framework`, `ImageIO.framework`.
2. Add the IIIThumbFlow folder to your project.
3. Implement the `IIIFlowViewDelegate` methods in your view controller:  
`- (NSInteger)numberOfColumns;`  
`- (NSInteger)numberOfCells;`  
`- (CGFloat)rateOfCache;`  
`- (IIIFlowCell *)flowView:(IIIFlowView *)flow cellAtIndex:(int)index;`  
`- (IIIBaseData *)dataSourceAtIndex:(int)index;`  


Check out `IIIFlowViewDelegate` for more information.

### Requirements ###
IIIThumbFlow uses ARC. If you are not using ARC in your project, add `'-fobjc-arc'` as a compiler flag for all the files in IIIThumbFlow.

### Included libraries ###
IIIThumbFlow uses [SDWebImage v2.0](1) to cache images. The author has done really great job on performance and memory usage optimization about images. See [How is SDWebImage better than X?][2]
[1]: https://github.com/rs/SDWebImage/tree/2.0-compat "SDWebImage" 
[2]: https://github.com/rs/SDWebImage/wiki/How-is-SDWebImage-better-than-X%3F

### Licenses ###
All source code is licensed under the [MIT License][3]
[3]: https://raw.github.com/sehone/IIIThumbFlow/master/LICENSE.md