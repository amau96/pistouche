//
//  LesRegions.h
//  QuizzGeoVin
//
//  Created by amaury blanc on 11-01-05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LesRegions : UITableViewController {
	NSMutableArray *monTableauDeRegions;
	NSString *titre;
}

@property(nonatomic,retain) NSString *titre;
@end
