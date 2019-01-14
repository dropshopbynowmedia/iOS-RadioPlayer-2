//
//  FMPlayHistoryCollectionView.m
//  iOS-RadioPlayer-2
//
//  Insert a UICollectionView in the interface builder, and assign it this
//  class. Then add a collection cell to represent each audio item, assign it
//  the FMPlaylistCollectionViewPlayCell class, and give it a reuse id
//  of 'audioItemCell'. Then add a resuable view cell, assign it the
//  FMPlayHistoryCollectionViewStationCell class, and give it a reuse id
//  of 'stationCell'. Make sure to wire up all the UI elements, and you're
//  golden!
//
//  Created by Eric Lambrecht on 5/19/17.
//  Copyright © 2017 Feed Media. All rights reserved.
//

#import "FMPlaylistCollectionView.h"
#import "FMResources.h"
#import <FeedMedia/FeedMedia.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+FMAdjustImageAlpha.h"

// Helper classes to represent an 'audio item' and a 'station' header.

@implementation FMPlaylistCollectionViewAudioItemCell

@end

@implementation FMPlaylistCollectionViewStationCell

@end

//
//
//

@interface FMPlaylistCollectionView ()

@property (weak, nonatomic) id closeTarget;
@property (nonatomic) SEL closeSelector;

@property (strong, nonatomic) UIImage *fadedLikeImage;
@property (strong, nonatomic) UIImage *fadedDislikeImage;

@end


@implementation FMPlaylistCollectionView

static NSString * const audioItemCellIdentifier = @"audioItemCell";
static NSString * const stationCellIdentifier = @"stationCell";
static UIEdgeInsets sectionInsets;

+ (void) initialize {
    if (self == [FMPlaylistCollectionView class]) {
        sectionInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

- (id) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
}

- (id) init {
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (void) setup {
    _station = nil;
    _fadedLikeImage = nil;
    _fadedDislikeImage = nil;
    
    self.dataSource = self;
    self.delegate = self;
    
    // no close targets by default
    _closeTarget = nil;
    _closeSelector = 0;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FMAudioPlayerCurrentItemDidBeginPlaybackNotification object:[FMAudioPlayer sharedPlayer]];
}

- (void) setTarget: (id) target andSelectorForCloseButton: (SEL) selector {
    _closeTarget = target;
    _closeSelector = selector;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _station.audioItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FMPlaylistCollectionViewAudioItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:audioItemCellIdentifier forIndexPath:indexPath];
    
    FMAudioItem *audioItem = _station.audioItems[indexPath.row];
    
    if (audioItem == nil) {
        NSLog(@"could not find audio item at index %ld", (long)indexPath.row);
        return nil;
    }
    
    // by default, truncate titles. selecting title will animate it
    cell.trackLabel.text = audioItem.name;
    cell.trackLabel.labelize = YES;

    // by default, truncate artist.
    cell.artistLabel.text = audioItem.artist;
    cell.artistLabel.labelize = YES;
    
    // fade out like/dislike buttons
    cell.likeButton.audioItem = audioItem;
    if (_fadedLikeImage == nil) {
        _fadedLikeImage = [[cell.likeButton imageForState:UIControlStateNormal] translucentImageWithAlpha:0.5];
    }
    [cell.likeButton setImage:_fadedLikeImage forState:UIControlStateNormal];
    
    cell.dislikeButton.audioItem = audioItem;
    if (_fadedDislikeImage == nil) {
        _fadedDislikeImage = [[cell.dislikeButton imageForState:UIControlStateNormal] translucentImageWithAlpha:0.5];
    }
    [cell.dislikeButton setImage:self.fadedDislikeImage forState:UIControlStateNormal];
    
    cell.playPauseButton.audioItem = audioItem;
    cell.playPauseButton.layer.cornerRadius = 30;
    
    NSString *bgImageUrl = [self backgroundLandscapeImageURLForOptions:audioItem.metadata andBackupOptions:_station.options];
    if (bgImageUrl != nil) {
        [cell.audioItemImage sd_setImageWithURL:[NSURL URLWithString:bgImageUrl] ];

    } else {
        cell.audioItemImage.image = _defaultAudioItemImage;
    }
    
    cell.audioItemImage.layer.cornerRadius = 5.0f;
    cell.audioItemImage.layer.masksToBounds = YES;

    return cell;
}

- (NSString *) backgroundLandscapeImageURLForOptions: (NSDictionary *) options andBackupOptions: (NSDictionary *) backupOptions {
    NSString *bgImageUrl = [options objectForKey:FMResources.backgroundLandscapeImageUrlPropertyName];
    
    if ((bgImageUrl != nil) && (bgImageUrl.length > 0)) {
        return bgImageUrl;
    }
    
    bgImageUrl = [options objectForKey:FMResources.backgroundImageUrlPropertyName];
    
    if ((bgImageUrl != nil) && (bgImageUrl.length > 0)) {
        return bgImageUrl;
    }
    
    if (backupOptions != nil) {
        return [self backgroundLandscapeImageURLForOptions:backupOptions andBackupOptions:nil];
    }
    
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        FMPlaylistCollectionViewStationCell * cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:stationCellIdentifier forIndexPath:indexPath];
        
        cell.stationLabel.text = _station.name;
        
        NSString *bgImageUrl = [self backgroundLandscapeImageURLForOptions:_station.options andBackupOptions:nil];

        if (bgImageUrl != nil) {
            [cell.stationImage sd_setImageWithURL:[NSURL URLWithString:bgImageUrl]];
            
        } else {
            cell.stationImage.image = _defaultAudioItemImage;
        }

        if (indexPath.section == 0) {
            cell.closeButton.hidden = NO;
            [cell.closeButton addTarget:self action:@selector(didTapCloseButton:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            cell.closeButton.hidden = YES;
        }
        
        return cell;
        
    } else {
        
        return nil;
    }
}

- (void) didTapCloseButton: (id) sender {
    
    // turn off all animation
    for (FMPlaylistCollectionViewAudioItemCell *cell in self.visibleCells) {
        cell.trackLabel.labelize = YES;
        cell.artistLabel.labelize = YES;
    }
    
    if (!_closeTarget) { return; }
    IMP imp = [_closeTarget methodForSelector:_closeSelector];
    void (*func)(id, SEL) = (void *)imp;
    func(_closeTarget, _closeSelector);
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FMPlaylistCollectionViewAudioItemCell *cell = (FMPlaylistCollectionViewAudioItemCell *) [collectionView cellForItemAtIndexPath:indexPath];
    
    // animate track name when selected
    cell.trackLabel.labelize = NO;
    cell.artistLabel.labelize = NO;
}

- (void)collectionView:(UICollectionView *)collectionView
didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    FMPlaylistCollectionViewAudioItemCell *cell = (FMPlaylistCollectionViewAudioItemCell *) [collectionView cellForItemAtIndexPath:indexPath];
    
    // de-animate track name when deselected
    cell.trackLabel.labelize = YES;
    cell.artistLabel.labelize = YES;
}


#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // items are width of screen minus margin and static height
    float paddingSpace = sectionInsets.left + sectionInsets.right;
    float availableWidth = self.bounds.size.width - paddingSpace;
    
    float imageHeight = (availableWidth - 30.0) * (4.0/7.0);
    float totalHeight = imageHeight
                            + 15.0 /* top margin */
                            + 15.0 /* image -> track */
                            + 20.0 /* track */
                            + 5.0  /* track -> artist */
                            + 14.0 /* release */
                            + 15.0  /* bottom margin */
    ;
    
    return CGSizeMake(availableWidth, totalHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    
    // section headers are width of screen and static height
    float availableWidth = self.bounds.size.width;
    
    return CGSizeMake(availableWidth, 65.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return sectionInsets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

@end
