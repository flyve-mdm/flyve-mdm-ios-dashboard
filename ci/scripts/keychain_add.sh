#!/bin/sh

#
#  LICENSE
# 
#  This file is part of Flyve MDM Admin Dashboard for iOS.
#
#  Admin Dashboard for iOS is a subproject of Flyve MDM.
#  Flyve MDM is a mobile device management software.
# 
#  Flyve MDM is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  Flyve MDM is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  -------------------------------------------------------------------
#  @author    Hector Rondon - <hrondon@teclib.com>
#  @copyright Copyright Teclib. All rights reserved.
#  @license   LGPLv3 https://www.gnu.org/licenses/lgpl-3.0.html
#  @link      https://github.com/flyve-mdm/ios-mdm-dashboard/
#  @link      http://flyve.org/ios-mdm-dashboard/
#  @link      https://flyve-mdm.com
#  -------------------------------------------------------------------
#

echo ----------------- Decrypt custom keychain ------------------
# Decrypt custom keychain
echo "$DIST_CER_ENC" | base64 -D > $CERTIFICATES_PATH/dist.cer.enc
echo "$DIST_P12_ENC" | base64 -D > $CERTIFICATES_PATH/dist.p12.enc
openssl aes-256-cbc -k "$KEYCHAIN_PASSWORD" -in $CERTIFICATES_PATH/dist.cer.enc -d -a -out $CERTIFICATES_PATH/dist.cer
openssl aes-256-cbc -k "$KEYCHAIN_PASSWORD" -in $CERTIFICATES_PATH/dist.p12.enc -d -a -out $CERTIFICATES_PATH/dist.p12
echo -------------Create the keychain with a password -----------
# Create the keychain with a password
security create-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME
security add-certificates -k $KEYCHAIN_NAME $CERTIFICATES_PATH/apple.cer $CERTIFICATES_PATH/dist.cer
echo ------------ Make the custom keychain default, so xcodebuild will use it for signing -------------
# Make the custom keychain default, so xcodebuild will use it for signing
security list-keychains -d user -s $KEYCHAIN_NAME
security default-keychain -s $KEYCHAIN_NAME
echo ------------------- Unlock the keychain --------------------
# Unlock the keychain
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME
echo ----- Set keychain timeout to 1 hour for long builds -------
# Set keychain timeout to 1 hour for long builds
# see http://www.egeek.me/2013/02/23/jenkins-and-xcode-user-interaction-is-not-allowed/
security set-keychain-settings -t 3600 -l ~/Library/Keychains/$KEYCHAIN_NAME
echo -------------- Add certificates to keychain ----------------
# Add certificates to keychain and allow codesign to access them
security import $CERTIFICATES_PATH/dist.p12 -k ~/Library/Keychains/$KEYCHAIN_NAME -P "$KEYCHAIN_PASSWORD" -T /usr/bin/codesign

security set-key-partition-list -S apple-tool:,apple: -s -k $KEYCHAIN_PASSWORD $KEYCHAIN_NAME
