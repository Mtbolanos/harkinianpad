// "Import JSON from Files": the iOS stand-in for dropping a file on the desktop window.
//
// The picked JSON is copied into the app and handed to the game as a real SDL_DROPFILE event, so Ship of
// Harkinian's own drop handlers process it exactly as on desktop: a randomizer spoiler (needed to join an Anchor
// room with the host's seed) or a shared configuration.
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "HarkinianPadJsonImport.h"
#include <SDL.h>
#include <imgui.h>
#include <atomic>
#include <mutex>
#include <string>

static std::atomic_bool sBusy(false);
static std::mutex sStatusMutex;
static std::string sStatus;

static void SetStatus(NSString* status) {
    std::lock_guard<std::mutex> lock(sStatusMutex);
    sStatus = status.UTF8String;
    SDL_Log("[HarkinianPad] JSON import: %s", sStatus.c_str());
}

// Same event SDL sends when a file is dropped on the window; libultraship's FileDropMgr dispatches it.
static void SendDropFile(NSString* path) {
    SDL_Event event = {};
    event.type = SDL_DROPFILE;
    event.drop.timestamp = SDL_GetTicks();
    event.drop.file = SDL_strdup(path.fileSystemRepresentation);
    SDL_Window* window = SDL_GetKeyboardFocus();
    if (window != nullptr) {
        event.drop.windowID = SDL_GetWindowID(window);
    }
    if (SDL_PushEvent(&event) != 1) {
        SDL_free(event.drop.file);
        SetStatus(@"Could not hand the file to the game. Retry.");
    }
}

static void ImportFile(NSURL* url) {
    const BOOL scoped = [url startAccessingSecurityScopedResource];
    NSData* data = [NSData dataWithContentsOfURL:url];
    if (scoped) {
        [url stopAccessingSecurityScopedResource];
    }
    if (data == nil) {
        SetStatus(@"Cannot read the selected file. Download it in Files and retry.");
        return;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSDictionary* object = [json isKindOfClass:NSDictionary.class] ? json : nil;
    // The checks SoH's handlers make (Rando_HandleSpoilerDrop, SoH_HandleConfigDrop).
    const BOOL spoiler = object[@"version"] != nil && object[@"finalSeed"] != nil;
    const BOOL config = object[@"CVars"] != nil;
    if (!spoiler && !config) {
        SetStatus(@"Not a randomizer spoiler or a Ship of Harkinian configuration JSON.");
        return;
    }

    // Spoilers stay in Documents/Randomizer (where SoH keeps its own), because the game reads them again when a
    // save is created. Configurations are applied once, so a temporary copy is enough.
    NSFileManager* files = NSFileManager.defaultManager;
    NSString* base = spoiler
        ? [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
              stringByAppendingPathComponent:@"Randomizer"]
        : [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImportedConfig"];
    NSError* error = nil;
    [files createDirectoryAtPath:base withIntermediateDirectories:YES attributes:nil error:nil];
    NSString* name = url.lastPathComponent.length > 0 ? url.lastPathComponent : @"imported.json";
    if (![name.pathExtension.lowercaseString isEqualToString:@"json"]) {
        name = [name stringByAppendingPathExtension:@"json"];
    }
    NSString* destination = [base stringByAppendingPathComponent:name];
    if (![data writeToFile:destination options:NSDataWritingAtomic error:&error]) {
        SetStatus(@"Cannot save the file. Check available storage and retry.");
        return;
    }
    SendDropFile(destination);
    SetStatus(spoiler ? [NSString stringWithFormat:@"Spoiler %@ imported. It loads on the file select screen.", name]
                      : [NSString stringWithFormat:@"Configuration %@ imported.", name]);
}

@interface HarkinianPadJsonPicker : NSObject <UIDocumentPickerDelegate>
@end

static HarkinianPadJsonPicker* sPickerDelegate;

@implementation HarkinianPadJsonPicker
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController*)controller {
    sBusy = false;
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
    if (urls.firstObject != nil) {
        ImportFile(urls.firstObject);
    }
    sBusy = false;
}
@end

void HarkinianPad_ImportJson(void) {
    if (sBusy.exchange(true)) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController* presenter = nil;
        for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive ||
                ![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }
            for (UIWindow* window in ((UIWindowScene*)scene).windows) {
                if (window.isKeyWindow) {
                    presenter = window.rootViewController;
                }
            }
        }
        while (presenter.presentedViewController != nil) {
            presenter = presenter.presentedViewController;
        }
        if (presenter == nil || presenter.isBeingDismissed) {
            SetStatus(@"Files is unavailable right now. Close other dialogs and retry.");
            sBusy = false;
            return;
        }
        if (sPickerDelegate == nil) {
            sPickerDelegate = [HarkinianPadJsonPicker new];
        }
        UIDocumentPickerViewController* picker =
            [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ UTTypeJSON ] asCopy:YES];
        picker.allowsMultipleSelection = NO;
        picker.delegate = sPickerDelegate;
        [presenter presentViewController:picker animated:YES completion:nil];
    });
}

void HarkinianPad_DrawJsonImport(const char* id) {
    ImGui::PushID(id);
    ImGui::BeginDisabled(sBusy.load());
    if (ImGui::Button("Import JSON from Files")) {
        HarkinianPad_ImportJson();
    }
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
        ImGui::SetTooltip("Loads a randomizer spoiler (for example the host's seed for Anchor) or a shared "
                          "configuration, like dropping the file on the desktop window.");
    }
    std::string status;
    {
        std::lock_guard<std::mutex> lock(sStatusMutex);
        status = sStatus;
    }
    if (!status.empty()) {
        ImGui::TextWrapped("%s", status.c_str());
    }
    ImGui::PopID();
}
