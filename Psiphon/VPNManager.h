/*
 * Copyright (c) 2017, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import <Foundation/Foundation.h>

// NSNotification name for VPN status change notifications.
#define kVPNStatusChangeNotificationName "VPNStatusChange"

#define kVPNManagerErrorDomain @"VPNManagerErrorDomain"
typedef NS_ENUM(NSInteger, VPNManagerErrorCode) {
    VPNManagerErrorLoadConfigsFailed = 1,
    VPNManagerErrorTooManyConfigsFounds = 2,
    VPNManagerErrorUserDeniedConfigInstall = 3,
    VPNManagerErrorNEStartFailed = 4,
    VPNManagerErrorNoTargetManager = 5,
};

typedef NS_ENUM(NSInteger, VPNStatus) {
    VPNStatusInvalid = 0,
    /*! @const VPNStatusDisconnected No network extension process is running (When restarting VPNManager status will be VPNStatusRestarting). */
    VPNStatusDisconnected = 1,
    /*! @const VPNStatusConnecting network extension process is running, and the tunnel has started (tunnel could be in connecting or connected state). */
    VPNStatusConnecting = 2,
    /*! @const VPNStatusConnected network extension process is running and the tunnel is connected. */
    VPNStatusConnected = 3,
    /*! @const VPNStatusReasserting network extension process is running, and the tunnel is reconnecting or has already connected. */
    VPNStatusReasserting = 4,
    /*! @const VPNStatusDisconnecting tunnel and the network extension process are being stopped.*/
    VPNStatusDisconnecting = 5,
    /*! @const VPNStatusRestarting Stopping previous network extension process, and starting a new one. */
    VPNStatusRestarting = 6,
    /*! @const VPNStatusNoTunnel Extension process is running, but Psiphon tunnel will not be started.
     * This is usually due to user's expired subscription or starting tunnel from system setting
     * without a valid subscription */
    VPNStatusNoTunnel = 7,
};

@interface VPNManager : NSObject

@property (nonatomic) BOOL startStopButtonPressed;

+ (instancetype _Nullable )sharedInstance;

/**
 * Starts the network extension process and also the tunnel.
 * VPN will not start until startVPN is called.
 * @param completionHandler If no errors occurred, then error is set to nil.
 *        Error code is set to one of VPNManagerError* errors.
 */
- (void)startTunnelWithCompletionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

/**
 * Signals the network extension to start the VPN.
 * startTunnel should be called before calling startVPN.
 */
- (void)startVPN;

/**
 * Stops the currently running network extension.
 * Note: If no network extension process is running nothing happens.
 */
- (void)restartVPN;

/**
 * Stops the tunnel and stops the network extension process.
 */
- (void)stopVPN;

/**
 * @return VPNManager status reflect NEVPNStatus of NEVPNManager
 * with the addition of a VPNStatusRestarting status.
 */
- (VPNStatus)getVPNStatus;

/**
 * @return TRUE if the VPN is in the Connecting, Connected or Reasserting state.
 */
- (BOOL)isVPNActive;

/**
 * @return TRUE if the VPN is in the Connected state.
 */
- (BOOL)isVPNConnected;

/**
 * @return TRUE if the tunnel has connected, FALSE otherwise.
 */
- (BOOL)isTunnelConnected;

// TODO: write docs
- (void)isTunnelStarted:(void (^)(NSError * _Nullable error, BOOL tunnelStarted))completionHandler;

/**
 * Whether or not VPN configuration is installed on the device.
 * @return TRUE if installed, FALSE otherwise.
 */
- (BOOL)isVPNConfigurationInstalled;

/**
 * Whether or not VPN configuration onDemand is enabled or not.
 * @return TRUE if enabled, FALSE otherwise.
 */
- (BOOL)isVPNConfigurationOnDemandEnabled;

/**
 * Updates and saves VPN configuration Connect On Demand.
 * - If onDemandEnabled is different from current VPN configuration setting, then the completionHandler
 *   changeSaved is set to TRUE with error set to nil.
 * - If onDemandEnabled is same as VPN configuration setting, then the completionHandler changeSaved
 *   is set to FALSE with error set to nil.
 * @param onDemandEnabled Toggle VPN configuration Connect On Demand capability.
 * @param completionHandler Block called after operation completes.
 */
- (void)updateVPNConfigurationOnDemandSetting:(BOOL)onDemandEnabled completionHandler:(void (^)(NSError * _Nullable error, BOOL changeSaved))completionHandler;

/**
 * Removes Connect On Demand rules from VPN configuration.
 * @param completionHandler If Connect On Demand rule is removed successfully,
 *        completionhandler error is set to nil. If VPNManager has no target manager
 *        error code is set to VPNManagerErrorNoTargetManager.
 */
- (void)removeConnectOnDemandRules:(nullable void (^)(NSError * _Nullable error))completionHandler;

@end
