//
//  IIIFlowView.m
//  IIIThumbFlow
//
//  Created by sehone on 12/21/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "IIIFlowView.h"
#import "IIIBaseData.h"
#import "UIImage+IIIThumb.h"
#import "SDImageCache+IIIThumb.h"

const CGFloat DOWNLOADING_PH_H = 80;
const CGFloat INDICATOR_SIZE = 20;

@interface IIIFlowView () {
    // Detect drag direction
    IIIDirection _direction;
    CGPoint _lastDragPoint;
    
    int _columnCount;
    int _cellCount;
    CGFloat _columnWidth;
    // Record heights of each column, useful when calculate cell insert point.
    NSMutableArray *_columnHeights;
    // Placeholder before image loaded
    NSMutableArray *_placeholders;
    // Placeholder for web image before downloading finished.
    UIView *_downloadingPlaceholder;
    UIActivityIndicatorView *_downloadingIndicator;
    CGFloat _cacheRate;
    // Top and bottom y of loaded scale.
    CGFloat _top;
    CGFloat _bottom;
    // Top and bottom y of last time loaded scale.
    CGFloat _l_top;
    CGFloat _l_bottom;
    
    // Record downloading URLs, check if this target is downloading.
    NSMutableDictionary *_downloadingURLs;
    
    CGFloat _cellPadding;
}
// Put reusable cells in this pool, to reduce memory cost if data source is huge.
@property (strong, nonatomic) NSMutableDictionary *cellPool;
// Record cell location & size for each image, each item is a NSValue of CGRect.
@property (strong, nonatomic) NSMutableArray *cellMap;
// Record loaded cells.
@property (strong, nonatomic) NSMutableDictionary *loadedCells;

@end


@implementation IIIFlowView
@synthesize flowDelegate = _flowDelegate;
@synthesize cellPool = _cellPool;
@synthesize cellMap = _cellMap;
@synthesize loadedCells = _loadedCells;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = iii_const_common_bg_color;
        self.delegate = self;
        _cellPadding = iii_const_common_cell_padding;
        
        _downloadingPlaceholder = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_downloadingPlaceholder];
        _downloadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, INDICATOR_SIZE, INDICATOR_SIZE)];
        [_downloadingPlaceholder addSubview:_downloadingIndicator];
        [self hideDownloadingPlaceholder];
        
        // Tap gesture recognizer, use it to calculate selected image index
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)]];
    }
    return self;
}

- (void)unloadData {
    [_columnHeights removeAllObjects];
    [_placeholders removeAllObjects];
    [_downloadingURLs removeAllObjects];
    NSArray *a = [self.loadedCells allKeys];
    IIIFlowCell *c;
    NSNumber *k;
    for (k in a) {
        c = [self.loadedCells objectForKey:k];
        [c unload];
        [c removeFromSuperview];
    }
    [self.loadedCells removeAllObjects];
    [self hideDownloadingPlaceholder];
}

/*
 * Invoke this method to do some prepare work for reloadData (before reloadData).
 * If column number or cell number changed in flowDelegate, invoke this method.
 *
 * NOTE: Setting of flowDelegate should be done for this method.
 */
- (void)prepareToReload {
    [self unloadData];
    
    _top = 0;
    _bottom = 0;
    _l_top = 0;
    _l_bottom = 0;
    _lastDragPoint = CGPointZero;
    self.contentOffset = CGPointZero;
    
    // Reset column, cell and cache rate information, in case delegate changed them.
    _cellCount = [self.flowDelegate numberOfCells];
    _columnCount = [self.flowDelegate numberOfColumns];
    if (!_columnCount) {
        _columnCount = 1;
    }
    _columnWidth = self.frame.size.width / _columnCount;
    _columnHeights = [NSMutableArray arrayWithCapacity:_columnCount];
    for (int i=0; i<_columnCount; i++) {
        [_columnHeights addObject:[NSNumber numberWithFloat:0.0f]];
    }
    _placeholders = [NSMutableArray arrayWithCapacity:0];
    _cacheRate = [self.flowDelegate rateOfCache];
    _downloadingURLs = [NSMutableDictionary dictionaryWithCapacity:0];
    CGFloat s = INDICATOR_SIZE;
    _downloadingIndicator.frame = (CGRect){{(_columnWidth-s)/2, (DOWNLOADING_PH_H-s)/2}, {s, s}};
    
    // Reset contentSize of scroll view.
    self.contentSize = self.frame.size;
    
    // Init some containers
    [self.cellPool removeAllObjects];
    self.cellPool = [NSMutableDictionary dictionaryWithCapacity:0];
    [self.cellMap removeAllObjects];
    self.cellMap = [NSMutableArray arrayWithCapacity:0];
    self.loadedCells = [NSMutableDictionary dictionaryWithCapacity:0];
}

/*
 * Data source might be large, so this view use cells with a recycle policy to  
 * save memory. When user scrolls the flow view, this method would check cells, 
 * load some cells and unload some unwanted cells, depends on if the cell is 
 * getting close to or getting away from visible area.
 *
 * Checking area should be as small as possible, it would prominently affect the
 * fluency of scroll animation.
 * Compare cache scales of this time and last time, find out different areas with
 * shift distance, ONLY check cells in these different areas. If a cell could be 
 * in both this and last time cache scale, don't check it.
 * If user scrolls 'too quickly', there might be no common area for cache scales
 * of this and last time. There is a blank area between these two cache scales. Do
 * not check cells in this blank area.
 */
- (void)reloadData {
    // Check re-prepare
    if (_cellCount != [self.flowDelegate numberOfCells] ||
        _columnCount != [self.flowDelegate numberOfColumns]) {
        [self prepareToReload];
    }
    // Calcualate the min checking areas, verbose but worth to.
    CGFloat y = self.contentOffset.y;
    CGFloat h = self.frame.size.height;
    IIIFlowCacheScale c = [self cacheScaleWithOffsetY:y];
    _top = c.top;
    _bottom = c.bottom;
    
    // first and last loaded cell indexes.
    int first = -1;
    int last = -1;
    int loadStart;
    CGFloat unloadEnd;
    NSArray *a = self.loadedCells.allKeys;
    if (a.count) {
        NSArray *sa = [a sortedArrayUsingSelector:@selector(compare:)];
        first = [[sa objectAtIndex:0] intValue];
        last = [[sa lastObject] intValue];
    }
    
    
    // Use bottom instead of top (considering the first reload).
    if (_bottom > _l_bottom) {  // Scroll DOWN
        if (_top > _l_bottom) {
            // Scroll DOWN 'too quickly', calculate new start
            loadStart = MAX(last+1, [self getIndexWithMaxHeight:_top start:last+1 end:self.cellMap.count-1]);
            unloadEnd = _l_bottom;
        } else {
            // Common case, don't load the last loaded one.
            loadStart = last + 1;
            unloadEnd = _top;
        }
        // Unload top section. IMPORTANT: first unload, then load, so that cellqueue can be smaller.
        if (_top > 0) {
            // Only when _top > 0 need to unload top section
            [self checkCellsFrom:first direction:DOWN endHeight:unloadEnd];
        }
        // Load bottom section. 
        [self checkCellsFrom:loadStart direction:DOWN endHeight:_bottom];
        
    } else {  // Scroll UP
        if (_l_top > _bottom) {  // Scroll UP 'too quickly'
            loadStart = MIN(first-1, [self getIndexWithMaxHeight:_bottom start:0 end:first-1]);
            unloadEnd = _l_top;
        } else {
            loadStart = first - 1;
            unloadEnd = _bottom;
        }
        // Unload bottom section.
        [self checkCellsFrom:last direction:UP endHeight:unloadEnd];
        // Load top section.
        [self checkCellsFrom:loadStart direction:UP endHeight:_top];
    }
    
    // Set scrollview content size, extra DOWNLOADING_PH_H height.
    CGFloat mch = [self maxColumn].height + DOWNLOADING_PH_H;
    if (mch > h) {
        self.contentSize = CGSizeMake(self.frame.size.width, mch);
    }
    
    // Record for next reload
    _l_top = _top;
    _l_bottom = _bottom;
}


/*
 * Check cells with a giving start index, end height edge, and checking direction.
 * If cell.frame.y exceeds the end height, stop checking and return.
 * If a cell is loaded, unload it, otherwise, load it (load image).
 * If a web image is not cached, checking would be suspended until the downloading
 * finished.
 */
- (void)checkCellsFrom:(int)si direction:(int)dir endHeight:(CGFloat)eh {
    NSNumber *k;
    IIIFlowCell *c;
    CGPoint p;
    
    for (int i=si; i<_cellCount && i >= 0; i+=dir) {
        p = [self getCellInsertPointWithIndex:i];
        // If dir == 1, check down, (p.y <= eh), if dir == -1, check up, (p.y >= eh)
        if ((p.y - eh) * dir > 0) {
            //NSLog(@"x %i: %f", i, p.y);
            break; // exceed end height, quit loop
        }
        
        k = [NSNumber numberWithInt:i];
        c = [self.loadedCells objectForKey:k];
        if (c) {
            // Unload cell
            [c unload];
            [self addCellToReuseQueue:c];
            // Remove from loaded cells dict
            [self.loadedCells removeObjectForKey:k];
            [c removeFromSuperview];
            //NSLog(@"- %i: %f", i, p.y);
            // Show placeholder
            UIView *v = [_placeholders objectAtIndex:i];
            [self addSubview:v];
            
        } else {
            // Load cell
            c = [self.flowDelegate flowView:self cellAtIndex:i];
            
            if ([self loadCell:c AtIndex:i]) {
                CGSize z = c.frame.size;
                c.frame = (CGRect){p, z};
                // Add cell to loaded cells dict
                [self.loadedCells setObject:c forKey:k];
                [self addSubview:c];
                //NSLog(@"+ %i: %f", i, p.y);
                // If it's the lowest cell.
                if (i == self.cellMap.count) {
                    if (c.isDownloading) {
                        c.isDownloading = NO;
                        [self hideDownloadingPlaceholder];
                    }
                    // Add point to cell map.
                    [self.cellMap addObject:[NSValue valueWithCGRect:c.frame]];
                    // Add columnHeight.
                    int j = p.x * _columnCount / self.frame.size.width; // column number
                    CGFloat h = [[_columnHeights objectAtIndex:j] floatValue];
                    [_columnHeights setObject:[NSNumber numberWithFloat:(h+c.frame.size.height)] atIndexedSubscript:j];
                    // Add placeholder
                    CGRect rect = [[_cellMap objectAtIndex:i] CGRectValue];
                    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(rect.origin.x+_cellPadding, rect.origin.y+_cellPadding, rect.size.width-_cellPadding*2, rect.size.height-_cellPadding*2)];
                    v.backgroundColor = [UIColor whiteColor];
                    
                    [_placeholders setObject:v atIndexedSubscript:i];
                    
                } else {
                    // If load a cell with index < cellMap.count, then there must be a placeholder
                    UIView *v = [_placeholders objectAtIndex:i];
                    [v removeFromSuperview];
                }
            } else {
                //NSLog(@"+* %i: %f", i, p.y);
                if (c.isDownloading) {
                    [self showDownloadingPlaceholder:p];
                }
                break;
            }
        } // End of load cell
    } // End of loop
    
}


/*
 * SDWebImage provides an approach to cache images (in both memory and disk layers). 
 * That's really a good job. For more information, see: 
 * https://github.com/rs/SDWebImage/wiki/How-is-SDWebImage-better-than-X%3F
 *
 * So loading from cache is a prefered choice. If not cached, then load from disc
 * or download the image.
 *
 * Loading original image in flow view is not appropriate, those images could use
 * up memory & CPU resources very quickly. So always load thumbnails.
 */
- (BOOL)loadCell:(IIIFlowCell *)cell AtIndex:(int)index {
    IIIBaseData *d = [self.flowDelegate dataSourceAtIndex:index];
    UIImage *thumb, *oImg;
    NSString *url;
    if (d.local_url.length) {
        url = d.local_url;
    } else if (d.web_url.length) {
        url = d.web_url;
    } else {
        return NO;
    }
    
    
    thumb = [UIImage thumbWithURL:url width:_columnWidth];
    
    if (!thumb) {
        // If thumb not cached, try to create thumb with original image.
        oImg = [[SDImageCache sharedThumbImageCache] imageFromKey:url];
        if (!oImg) {
            // If original image not cached.
            if (d.local_url.length) {
                // If it's a local url, get original image from file.
                oImg = [UIImage imageWithContentsOfFile:url];
                if (!oImg) {
                    return NO;
                } else {
                    // Set cache for original image
                    [[SDImageCache sharedThumbImageCache] storeImage:oImg forKey:url];
                }
            } else {
                // If it's a web url, asynchronize download image, suspend loading cells
                if (![_downloadingURLs objectForKey:d.web_url]) {
                    [SDWebImageDownloader downloaderWithURL:[NSURL URLWithString:d.web_url] delegate:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:INDEX_KEY] lowPriority:YES];
                    // Mark this url as downloading, don't repeat requesting when next time check this cell.
                    [_downloadingURLs setObject:[NSString stringWithFormat:@"%i", index] forKey:d.web_url];
                    cell.isDownloading = YES;
                }
                return NO;
            }
        }
        thumb = [oImg setThumbWithURL:url width:_columnWidth];
    }
    [cell loadWithImage:thumb cellWidth:_columnWidth];
    return YES;
}


- (void)unloadCell:(IIIFlowCell *)cell {
    [cell unload];
}

/*
 * Every cell has its position in flow view. It's fixed until the next time
 * invoke reloadView of flow view.
 */
- (CGPoint)getCellInsertPointWithIndex:(int)index {
    // Look up in the cells map first.
    if (index < self.cellMap.count) {
        NSValue *val = [self.cellMap objectAtIndex:index];
        return val.CGRectValue.origin;
    }
    // If not exists, insert in the column with a MIN height
    IIIFlowColumnHeight h = [self minColumn];
    CGFloat x = self.frame.size.width * h.index / _columnCount;
    return CGPointMake(x, h.height);
}



- (IIIFlowCell *)dequeueReusableCellWithId: (NSString *)idStr {
    if (0 == idStr.length) {
        return nil;
    }
    NSMutableArray *availableCells = [self.cellPool objectForKey:idStr];
    if (availableCells.count > 0) {
        IIIFlowCell *cell = [availableCells lastObject];
        [availableCells removeObject:cell];
        return cell;
    }
    return nil;
}


- (void)addCellToReuseQueue: (IIIFlowCell *)cell {
    if (0 == cell.reuseId.length) {
        return;
    }
    
    NSMutableArray *availableCells = [self.cellPool objectForKey:cell.reuseId];
    if (0 == availableCells.count) {
        availableCells = [NSMutableArray arrayWithObject:cell];
        [self.cellPool setObject:availableCells forKey:cell.reuseId];
    } else {
        [availableCells addObject:cell];
    }
}


- (void)showDownloadingPlaceholder:(CGPoint)p {
    CGRect f = _downloadingPlaceholder.frame;
    f.origin = p;
    _downloadingPlaceholder.frame = f;
    _downloadingPlaceholder.hidden = NO;
    [_downloadingIndicator startAnimating];
}

- (void)hideDownloadingPlaceholder {
    _downloadingPlaceholder.hidden = YES;
    [_downloadingIndicator stopAnimating];
}



#pragma mark - Util methods

// Get min height column, usually invoke this method to locate the next loading cell.
- (IIIFlowColumnHeight)minColumn {
    if (0 == _columnHeights.count) {
        return (IIIFlowColumnHeight){0, 0};
    }
    int minColIndex = 0;
    CGFloat minHeight = [[_columnHeights objectAtIndex:minColIndex] floatValue];
    CGFloat h;
    for (int i=0; i<_columnHeights.count; i++) {
        h = [[_columnHeights objectAtIndex:i] floatValue];
        if (h < minHeight) {
            minHeight = h;
            minColIndex = i;
        }
    }
    return (IIIFlowColumnHeight){minColIndex, minHeight};
}

// Get max height column, usually invoke it to set contentSize of scroll view.
- (IIIFlowColumnHeight)maxColumn {
    if (0 == _columnHeights.count) {
        return (IIIFlowColumnHeight){0, 0};
    }
    int maxColIndex = 0;
    CGFloat maxHeight = [[_columnHeights objectAtIndex:maxColIndex] floatValue];
    CGFloat h;
    for (int i=0; i<_columnHeights.count; i++) {
        h = [[_columnHeights objectAtIndex:i] floatValue];
        if (h > maxHeight) {
            maxHeight = h;
            maxColIndex = i;
        }
    }
    return (IIIFlowColumnHeight){maxColIndex, maxHeight};
}

// Get top and bottom y of cache scale, usually invoke it to set _top and _bottom
- (IIIFlowCacheScale)cacheScaleWithOffsetY:(CGFloat)y {
    CGFloat h = self.frame.size.height;
    CGFloat len = _cacheRate * h; // length of cache area
    
    return (IIIFlowCacheScale){y-len < 0 ? 0 : y-len, y + h + len};
}

/*
 * Binary tree search in an ordered array, to calculate start index of the last 
 * cell in self.cellMap, whose height is no more than 'maxH'.
 * 
 * h[i] <= maxH && h[i+1] > maxH
 * 
 * Invoke this method to locate new start point, so as to decrease checking loop,
 * in case of user scroll 'too quickly'.
 * 
 * NOTE: 'end' should be inited as self.cellMap.count-1, not self.cellMap.count.
 */
- (int)getIndexWithMaxHeight:(CGFloat)maxH start:(int)start end:(int)end {
    // -1: not found
    int result = -1;
    CGFloat y;
    // If sub-tree empty.
    if (start > end) {
        return result;
    }
    
    // If min > maxH, not found.
    y = [[self.cellMap objectAtIndex:start] CGRectValue].origin.y;
    if (y > maxH) {
        return result;
    }
    // If max < maxH, return end, all elements in array lower than maxH.
    y = [[self.cellMap objectAtIndex:end] CGRectValue].origin.y;
    if (y < maxH) {
        return end;
    }
    
    // So now, h[start] <= maxH <= h[end]
    if (end - start <= 1) {
        return end;
    }
    
    int mid = (start + end) / 2;
    y = [[self.cellMap objectAtIndex:mid] CGRectValue].origin.y;
    if (y > maxH) {
        // If h(mid) > maxH, search left sub-tree.
        return [self getIndexWithMaxHeight:maxH start:start end:mid-1];
    } else {
        // If h(mid) <= maxH, mid is a candidate, search right sub-tree.
        return MAX(mid, [self getIndexWithMaxHeight:maxH start:mid+1 end:end]);
    }
}



#pragma mark - SDWebImageDownloaderDelegate methods
- (void)imageDownloader:(SDWebImageDownloader *)downloader didFinishWithImage:(UIImage *)image {
    int index = [[downloader.userInfo objectForKey:INDEX_KEY] intValue];
    NSString *urlStr = downloader.url.absoluteString;
    
    if ([[NSString stringWithFormat:@"%i", index] isEqualToString:[_downloadingURLs objectForKey:urlStr]]) {
        
        // Mark this url not downloading
        [_downloadingURLs removeObjectForKey:urlStr];
        
        // Set cache for web url
        [[SDImageCache sharedThumbImageCache] storeImage:image forKey:urlStr];
        
        // Continue to check cells (In case user changed datasource, check index&url first)
        if (index < [self.flowDelegate numberOfCells]) {
            IIIBaseData *d = [self.flowDelegate dataSourceAtIndex:index];
            if ([d.web_url isEqualToString:urlStr]) {
                [self checkCellsFrom:index direction:DOWN endHeight:_bottom];
                // Invoke delegate
                if ([self.flowDelegate respondsToSelector:@selector(downloadImageSucceed:atIndex:)]) {
                    [self.flowDelegate downloadImageSucceed:image atIndex:index];
                }
            }
        }
    }
}

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFailWithError:(NSError *)error {
    int index = [[downloader.userInfo objectForKey:INDEX_KEY] intValue];
    NSString *urlStr = downloader.url.absoluteString;
    NSLog(@"Image download error at index %i:%@ url:%@", index, error.localizedDescription, urlStr);
    
    if ([[NSString stringWithFormat:@"%i", index] isEqualToString:[_downloadingURLs objectForKey:urlStr]]) {
        // Mark this url not downloading
        [_downloadingURLs removeObjectForKey:urlStr];
        
        if (index < [self.flowDelegate numberOfCells]) {
            IIIBaseData *d = [self.flowDelegate dataSourceAtIndex:index];
            if ([d.web_url isEqualToString:urlStr]) {
                // Invoke delegate
                if ([self.flowDelegate respondsToSelector:@selector(downloadImageFailed:atIndex:)]) {
                    [self.flowDelegate downloadImageFailed:error atIndex:index];
                }
            }
        }
    }
}



#pragma mark - UIScrollViewDelegate methods
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // detect direction
    _direction = self.contentOffset.y > _lastDragPoint.y ? DOWN : UP;
    _lastDragPoint = self.contentOffset;
    if ([self.flowDelegate respondsToSelector:@selector(didScrolledWithDirection:)]) {
        [self.flowDelegate didScrolledWithDirection:_direction];
    }
    
    // To keep scroll animation fluent, reloadData directly only when no decelerate.
    if (!decelerate) {
        // There is no decelerate, drag slowly
        [self reloadData];
    } else {
        // With even a max speed scroll by human finger, contentOffset would 
        // shift for no more than SAFE_SCROLL_LENGTH.
        // If distance between visible area and cache edge is less than
        // SAFE_SCROLL_LENGTH, the view needs to reloadData, otherwise, user
        // might see unloaded scroll view background, with placeholders.
        CGFloat vt = self.contentOffset.y;
        CGFloat vb = self.contentOffset.y + self.frame.size.height;
        if ((abs(vb - _l_bottom) < SAFE_SCROLL_LENGTH) ||
            ((abs(vt - _l_top) < SAFE_SCROLL_LENGTH) && _l_top > 0)) {
            [self reloadData];
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // There is a decelerate, drag quickly
    [self reloadData];
}


// Return selected cell index, if no cell selected return -1.
- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture {
    CGPoint p = [gesture locationInView:self];
    int index = -1;
    int i = [self getIndexWithMaxHeight:p.y start:0 end:self.cellMap.count-1];
    CGRect r;
    CGFloat x, y, w, h;
    for (int j=i; j>=0; j--) {
        r = [[self.cellMap objectAtIndex:j] CGRectValue];
        x = r.origin.x;
        y = r.origin.y;
        w = r.size.width;
        h = r.size.height;
        if ((p.x >= x) && (p.x <= (x+w)) && (p.y >= y) && (p.y <= (y+h))) {
            // Found
            index = j;
            break;
        }
        if ((p.x >= x) && (p.x <= (x+w)) && (p.y>(y+h))) {
            // If in save column as p, and cell bottom less than p.y, quit loop,
            // impossible to find it in following loops.
            break;
        }
    }
    if ([self.flowDelegate respondsToSelector:@selector(didSelectCellAtIndex:)]) {
        [self.flowDelegate didSelectCellAtIndex:index];
    }
}

@end
