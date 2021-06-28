//
//  EverouDeviceCell.h
//  EverouSample
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EverouDeviceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomLabel;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@end

NS_ASSUME_NONNULL_END
