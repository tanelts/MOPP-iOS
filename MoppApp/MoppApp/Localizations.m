//
// Autogenerated by Laurine - by Jiri Trecak ( http://jiritrecak.com, @jiritrecak )
// Do not change this file manually!
//


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Imports

#import "Localizations.h"


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Header

@implementation _Localizations

- (NSString *)TestString {
    return NSLocalizedStringFromTable(@"test_string", nil, nil);
}

+ (_Localizations *)sharedInstance {

    static dispatch_once_t once;
    static _Localizations *instance;
    dispatch_once(&once, ^{
        instance = [[_Localizations alloc] init];
    });
    return instance;
}
@end

