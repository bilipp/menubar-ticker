#import "AppDelegate.h"

#import "Music.h"
#import "Spotify.h"

const NSTimeInterval kPollingInterval = 5.0;


@interface AppDelegate ()

@property (nonatomic, retain) MusicApplication *music;
@property (nonatomic, retain) SpotifyApplication *spotify;

@property (nonatomic, retain) NSStatusItem *statusItem;
@property (nonatomic, retain) NSTimer *timer;

@end


@implementation AppDelegate

@synthesize music;
@synthesize spotify;

@synthesize statusItem;
@synthesize statusMenu;
@synthesize timer;

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];

    self.music = nil;
    self.spotify = nil;
    
    self.statusItem = nil;
    self.statusMenu = nil;
    
    [self.timer invalidate];
    self.timer = nil;
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kPollingInterval
                                                  target:self
                                                selector:@selector(timerDidFire:)
                                                userInfo:nil
                                                 repeats:YES];

    // As of February 2021, notifications from Music.app are still coming in through
    // com.apple.iTunes.playerInfo and not com.apple.music.playerInfo.
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(didReceivePlayerNotification:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(didReceivePlayerNotification:)
                                                            name:@"com.apple.music.playerInfo"
                                                          object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(didReceivePlayerNotification:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
}

- (void)awakeFromNib
{
    self.music = [SBApplication applicationWithBundleIdentifier:@"com.apple.music"];
    self.spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;
    self.statusItem.button.toolTip = @"Menu Bar Ticker";
    
    [self updateTrackInfo];
}


- (void)updateTrackInfo
{
    id currentTrack = nil;
    NSString *trackInfo = @"♫";
    
    if ([self.music isRunning] && [self.music playerState] == MusicEPlSPlaying) {
        currentTrack = [self.music currentTrack];
        trackInfo = [NSString stringWithFormat:@"%@ - %@ (%@ / %@)",
                     [currentTrack artist],
                     [currentTrack name],
                     [self formatTime:[self.music playerPosition]],
                     [self formatTime:[currentTrack duration]]];
    } else if ([self.spotify isRunning] && [self.spotify playerState] == SpotifyEPlSPlaying) {
        currentTrack = [self.spotify currentTrack];
        trackInfo = [NSString stringWithFormat:@"%@ - %@ (%@ / %@)",
                     [currentTrack artist],
                     [currentTrack name],
                     [self formatTime:[self.spotify playerPosition]],
                     [self formatTime:[currentTrack duration]]];
    }

    self.statusItem.button.title = trackInfo;
}

- (NSString *)formatTime:(NSTimeInterval)timeInterval
{
    NSInteger minutes = (NSInteger)(timeInterval / 60.0);
    NSInteger seconds = (NSInteger)fmod(timeInterval, 60.0);
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)timerDidFire:(NSTimer *)theTimer
{
    [self updateTrackInfo];
}

- (void)didReceivePlayerNotification:(NSNotification *)notification
{
    [self updateTrackInfo];
}

@end
