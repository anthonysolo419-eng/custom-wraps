#!/usr/bin/env python3
"""Generate EbaySellerMessenger.xcodeproj/project.pbxproj"""

import uuid
import os

def make_id():
    return uuid.uuid4().hex[:24].upper()

# Fixed IDs for structural elements
PROJECT_ID = "A1B2C3D4E5F6A1B2C3D4E5F6"
TARGET_ID  = "B1C2D3E4F5A6B1C2D3E4F5A6"
MAIN_GROUP_ID = "C1D2E3F4A5B6C1D2E3F4A5B6"
PRODUCTS_GROUP_ID = "D1E2F3A4B5C6D1E2F3A4B5C6"
SOURCES_PHASE_ID  = "E1F2A3B4C5D6E1F2A3B4C5D6"
RESOURCES_PHASE_ID = "F1A2B3C4D5E6F1A2B3C4D5E6"
FWKS_PHASE_ID = "A2B3C4D5E6F1A2B3C4D5E6F1"
PRODUCT_REF_ID = "B2C3D4E5F6A1B2C3D4E5F6A1"
DEBUG_CONFIG_LIST_ID = "C2D3E4F5A6B1C2D3E4F5A6B1"
RELEASE_CONFIG_LIST_ID = "D2E3F4A5B6C1D2E3F4A5B6C1"
PROJ_DEBUG_ID  = "E2F3A4B5C6D1E2F3A4B5C6D1"
PROJ_RELEASE_ID = "F2A3B4C5D6E1F2A3B4C5D6E1"
TGT_DEBUG_ID   = "A3B4C5D6E1F2A3B4C5D6E1F2"
TGT_RELEASE_ID = "B3C4D5E6F1A2B3C4D5E6F1A2"
INFOPLIST_REF_ID = "C3D4E5F6A1B2C3D4E5F6A1B2"

SWIFT_FILES = [
    ("EbaySellerMessengerApp.swift", "EbaySellerMessenger"),
    ("Models/Coupon.swift", "EbaySellerMessenger/Models"),
    ("Models/EbayAuth.swift", "EbaySellerMessenger/Models"),
    ("Models/Message.swift", "EbaySellerMessenger/Models"),
    ("Models/Order.swift", "EbaySellerMessenger/Models"),
    ("Services/EbayAPIService.swift", "EbaySellerMessenger/Services"),
    ("Services/EbayAuthService.swift", "EbaySellerMessenger/Services"),
    ("Services/MessagingService.swift", "EbaySellerMessenger/Services"),
    ("Services/NotificationService.swift", "EbaySellerMessenger/Services"),
    ("Services/OrdersService.swift", "EbaySellerMessenger/Services"),
    ("Utilities/Extensions.swift", "EbaySellerMessenger/Utilities"),
    ("Utilities/KeychainHelper.swift", "EbaySellerMessenger/Utilities"),
    ("ViewModels/AuthViewModel.swift", "EbaySellerMessenger/ViewModels"),
    ("ViewModels/ConversationViewModel.swift", "EbaySellerMessenger/ViewModels"),
    ("ViewModels/OrdersViewModel.swift", "EbaySellerMessenger/ViewModels"),
    ("Views/Auth/CredentialsSetupView.swift", "EbaySellerMessenger/Views/Auth"),
    ("Views/Auth/LoginView.swift", "EbaySellerMessenger/Views/Auth"),
    ("Views/Common/LoadingView.swift", "EbaySellerMessenger/Views/Common"),
    ("Views/Common/MainTabView.swift", "EbaySellerMessenger/Views/Common"),
    ("Views/Messaging/BulkMessageView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Messaging/ConversationView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Messaging/ConversationsListView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Messaging/CouponPickerView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Messaging/MessageBubbleView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Messaging/MessageInputView.swift", "EbaySellerMessenger/Views/Messaging"),
    ("Views/Orders/OrderDetailView.swift", "EbaySellerMessenger/Views/Orders"),
    ("Views/Orders/OrderRowView.swift", "EbaySellerMessenger/Views/Orders"),
    ("Views/Orders/OrdersListView.swift", "EbaySellerMessenger/Views/Orders"),
]

# Assign IDs to each file
file_ids = {}  # path -> (file_ref_id, build_file_id)
for path, _ in SWIFT_FILES:
    file_ids[path] = (make_id(), make_id())

info_plist_build_id = make_id()

# Group structure
GROUPS = {
    "Models": make_id(),
    "Services": make_id(),
    "Utilities": make_id(),
    "ViewModels": make_id(),
    "Views": make_id(),
    "Views/Auth": make_id(),
    "Views/Common": make_id(),
    "Views/Messaging": make_id(),
    "Views/Orders": make_id(),
}
APP_GROUP_ID = make_id()  # EbaySellerMessenger group (root of sources)


def files_in_group(prefix):
    return [path for path, _ in SWIFT_FILES if path.startswith(prefix + "/") and "/" not in path[len(prefix)+1:]]


pbx = []
pbx.append("// !$*UTF8*$!")
pbx.append("{")
pbx.append("\tarchiveVersion = 1;")
pbx.append("\tclasses = {")
pbx.append("\t};")
pbx.append("\tobjectVersion = 56;")
pbx.append("\tobjects = {")
pbx.append("")

# PBXBuildFile
pbx.append("/* Begin PBXBuildFile section */")
for path, (fref, bfile) in file_ids.items():
    name = os.path.basename(path)
    pbx.append(f"\t\t{bfile} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {name} */; }};")
pbx.append(f"\t\t{info_plist_build_id} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {INFOPLIST_REF_ID} /* Info.plist */; }};")
pbx.append("/* End PBXBuildFile section */")
pbx.append("")

# PBXFileReference
pbx.append("/* Begin PBXFileReference section */")
pbx.append(f"\t\t{PRODUCT_REF_ID} /* EbaySellerMessenger.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = EbaySellerMessenger.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
pbx.append(f"\t\t{INFOPLIST_REF_ID} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
for path, (fref, _) in file_ids.items():
    name = os.path.basename(path)
    pbx.append(f"\t\t{fref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
pbx.append("/* End PBXFileReference section */")
pbx.append("")

# PBXFrameworksBuildPhase
pbx.append("/* Begin PBXFrameworksBuildPhase section */")
pbx.append(f"\t\t{FWKS_PHASE_ID} /* Frameworks */ = {{")
pbx.append("\t\t\tisa = PBXFrameworksBuildPhase;")
pbx.append("\t\t\tbuildActionMask = 2147483647;")
pbx.append("\t\t\tfiles = (")
pbx.append("\t\t\t);")
pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
pbx.append("\t\t};")
pbx.append("/* End PBXFrameworksBuildPhase section */")
pbx.append("")

# PBXGroup
pbx.append("/* Begin PBXGroup section */")

# Root main group
pbx.append(f"\t\t{MAIN_GROUP_ID} = {{")
pbx.append("\t\t\tisa = PBXGroup;")
pbx.append("\t\t\tchildren = (")
pbx.append(f"\t\t\t\t{APP_GROUP_ID} /* EbaySellerMessenger */,")
pbx.append(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tsourceTree = \"<group>\";")
pbx.append("\t\t};")

# Products group
pbx.append(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
pbx.append("\t\t\tisa = PBXGroup;")
pbx.append("\t\t\tchildren = (")
pbx.append(f"\t\t\t\t{PRODUCT_REF_ID} /* EbaySellerMessenger.app */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tname = Products;")
pbx.append("\t\t\tsourceTree = \"<group>\";")
pbx.append("\t\t};")

# App group (EbaySellerMessenger sources root)
root_files = [path for path, _ in SWIFT_FILES if "/" not in path]
pbx.append(f"\t\t{APP_GROUP_ID} /* EbaySellerMessenger */ = {{")
pbx.append("\t\t\tisa = PBXGroup;")
pbx.append("\t\t\tchildren = (")
for path in root_files:
    fref, _ = file_ids[path]
    pbx.append(f"\t\t\t\t{fref} /* {path} */,")
pbx.append(f"\t\t\t\t{INFOPLIST_REF_ID} /* Info.plist */,")
for gname in ["Models", "Services", "Utilities", "ViewModels", "Views"]:
    pbx.append(f"\t\t\t\t{GROUPS[gname]} /* {gname} */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tpath = EbaySellerMessenger;")
pbx.append("\t\t\tsourceTree = \"<group>\";")
pbx.append("\t\t};")

# Subgroups
def make_group(group_key, group_name, children_keys, sub_groups=None):
    pbx.append(f"\t\t{GROUPS[group_key]} /* {group_name} */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for path in children_keys:
        fref, _ = file_ids[path]
        pbx.append(f"\t\t\t\t{fref} /* {os.path.basename(path)} */,")
    if sub_groups:
        for sg_key in sub_groups:
            sg_name = sg_key.split("/")[-1]
            pbx.append(f"\t\t\t\t{GROUPS[sg_key]} /* {sg_name} */,")
    pbx.append("\t\t\t);")
    pbx.append(f"\t\t\tpath = {group_name};")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

def paths_directly_in(prefix):
    return [path for path, _ in SWIFT_FILES
            if path.startswith(prefix + "/")
            and "/" not in path[len(prefix)+1:]]

make_group("Models", "Models", paths_directly_in("Models"))
make_group("Services", "Services", paths_directly_in("Services"))
make_group("Utilities", "Utilities", paths_directly_in("Utilities"))
make_group("ViewModels", "ViewModels", paths_directly_in("ViewModels"))
make_group("Views", "Views", [], sub_groups=["Views/Auth", "Views/Common", "Views/Messaging", "Views/Orders"])
make_group("Views/Auth", "Auth", paths_directly_in("Views/Auth"))
make_group("Views/Common", "Common", paths_directly_in("Views/Common"))
make_group("Views/Messaging", "Messaging", paths_directly_in("Views/Messaging"))
make_group("Views/Orders", "Orders", paths_directly_in("Views/Orders"))

pbx.append("/* End PBXGroup section */")
pbx.append("")

# PBXNativeTarget
pbx.append("/* Begin PBXNativeTarget section */")
pbx.append(f"\t\t{TARGET_ID} /* EbaySellerMessenger */ = {{")
pbx.append("\t\t\tisa = PBXNativeTarget;")
pbx.append(f"\t\t\tbuildConfigurationList = {DEBUG_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"EbaySellerMessenger\" */;")
pbx.append("\t\t\tbuildPhases = (")
pbx.append(f"\t\t\t\t{SOURCES_PHASE_ID} /* Sources */,")
pbx.append(f"\t\t\t\t{RESOURCES_PHASE_ID} /* Resources */,")
pbx.append(f"\t\t\t\t{FWKS_PHASE_ID} /* Frameworks */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tbuildRules = (")
pbx.append("\t\t\t);")
pbx.append("\t\t\tdependencies = (")
pbx.append("\t\t\t);")
pbx.append("\t\t\tname = EbaySellerMessenger;")
pbx.append(f"\t\t\tproductName = EbaySellerMessenger;")
pbx.append(f"\t\t\tproductReference = {PRODUCT_REF_ID} /* EbaySellerMessenger.app */;")
pbx.append("\t\t\tproductType = \"com.apple.product-type.application\";")
pbx.append("\t\t};")
pbx.append("/* End PBXNativeTarget section */")
pbx.append("")

# PBXProject
pbx.append("/* Begin PBXProject section */")
pbx.append(f"\t\t{PROJECT_ID} /* Project object */ = {{")
pbx.append("\t\t\tisa = PBXProject;")
pbx.append("\t\t\tattributes = {")
pbx.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
pbx.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
pbx.append("\t\t\t\tLastUpgradeCheck = 1500;")
pbx.append("\t\t\t\tTargetAttributes = {")
pbx.append(f"\t\t\t\t\t{TARGET_ID} = {{")
pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
pbx.append("\t\t\t\t\t};")
pbx.append("\t\t\t\t};")
pbx.append("\t\t\t};")
pbx.append(f"\t\t\tbuildConfigurationList = {RELEASE_CONFIG_LIST_ID} /* Build configuration list for PBXProject \"EbaySellerMessenger\" */;")
pbx.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
pbx.append("\t\t\tdevelopmentRegion = en;")
pbx.append("\t\t\thasScannedForEncodings = 0;")
pbx.append("\t\t\tknownRegions = (")
pbx.append("\t\t\t\ten,")
pbx.append("\t\t\t\tBase,")
pbx.append("\t\t\t);")
pbx.append(f"\t\t\tmainGroup = {MAIN_GROUP_ID};")
pbx.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;")
pbx.append("\t\t\tprojectDirPath = \"\";")
pbx.append("\t\t\tprojectRoot = \"\";")
pbx.append("\t\t\ttargets = (")
pbx.append(f"\t\t\t\t{TARGET_ID} /* EbaySellerMessenger */,")
pbx.append("\t\t\t);")
pbx.append("\t\t};")
pbx.append("/* End PBXProject section */")
pbx.append("")

# PBXResourcesBuildPhase
pbx.append("/* Begin PBXResourcesBuildPhase section */")
pbx.append(f"\t\t{RESOURCES_PHASE_ID} /* Resources */ = {{")
pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
pbx.append("\t\t\tbuildActionMask = 2147483647;")
pbx.append("\t\t\tfiles = (")
pbx.append(f"\t\t\t\t{info_plist_build_id} /* Info.plist in Resources */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
pbx.append("\t\t};")
pbx.append("/* End PBXResourcesBuildPhase section */")
pbx.append("")

# PBXSourcesBuildPhase
pbx.append("/* Begin PBXSourcesBuildPhase section */")
pbx.append(f"\t\t{SOURCES_PHASE_ID} /* Sources */ = {{")
pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
pbx.append("\t\t\tbuildActionMask = 2147483647;")
pbx.append("\t\t\tfiles = (")
for path, (_, bfile) in file_ids.items():
    name = os.path.basename(path)
    pbx.append(f"\t\t\t\t{bfile} /* {name} in Sources */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
pbx.append("\t\t};")
pbx.append("/* End PBXSourcesBuildPhase section */")
pbx.append("")

# XCBuildConfiguration
common_settings = """				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

pbx.append("/* Begin XCBuildConfiguration section */")

# Project Debug
pbx.append(f"\t\t{PROJ_DEBUG_ID} /* Debug */ = {{")
pbx.append("\t\t\tisa = XCBuildConfiguration;")
pbx.append("\t\t\tbuildSettings = {")
pbx.append(common_settings)
pbx.append("\t\t\t};")
pbx.append("\t\t\tname = Debug;")
pbx.append("\t\t};")

# Project Release
pbx.append(f"\t\t{PROJ_RELEASE_ID} /* Release */ = {{")
pbx.append("\t\t\tisa = XCBuildConfiguration;")
pbx.append("\t\t\tbuildSettings = {")
pbx.append("""				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;""")
pbx.append("\t\t\t};")
pbx.append("\t\t\tname = Release;")
pbx.append("\t\t};")

# Target Debug
pbx.append(f"\t\t{TGT_DEBUG_ID} /* Debug */ = {{")
pbx.append("\t\t\tisa = XCBuildConfiguration;")
pbx.append("\t\t\tbuildSettings = {")
pbx.append("""				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = EbaySellerMessenger/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.ebaymessenger.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";""")
pbx.append("\t\t\t};")
pbx.append("\t\t\tname = Debug;")
pbx.append("\t\t};")

# Target Release
pbx.append(f"\t\t{TGT_RELEASE_ID} /* Release */ = {{")
pbx.append("\t\t\tisa = XCBuildConfiguration;")
pbx.append("\t\t\tbuildSettings = {")
pbx.append("""				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = EbaySellerMessenger/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.ebaymessenger.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";""")
pbx.append("\t\t\t};")
pbx.append("\t\t\tname = Release;")
pbx.append("\t\t};")
pbx.append("/* End XCBuildConfiguration section */")
pbx.append("")

# XCConfigurationList
pbx.append("/* Begin XCConfigurationList section */")
pbx.append(f"\t\t{DEBUG_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"EbaySellerMessenger\" */ = {{")
pbx.append("\t\t\tisa = XCConfigurationList;")
pbx.append("\t\t\tbuildConfigurations = (")
pbx.append(f"\t\t\t\t{TGT_DEBUG_ID} /* Debug */,")
pbx.append(f"\t\t\t\t{TGT_RELEASE_ID} /* Release */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
pbx.append("\t\t\tdefaultConfigurationName = Release;")
pbx.append("\t\t};")

pbx.append(f"\t\t{RELEASE_CONFIG_LIST_ID} /* Build configuration list for PBXProject \"EbaySellerMessenger\" */ = {{")
pbx.append("\t\t\tisa = XCConfigurationList;")
pbx.append("\t\t\tbuildConfigurations = (")
pbx.append(f"\t\t\t\t{PROJ_DEBUG_ID} /* Debug */,")
pbx.append(f"\t\t\t\t{PROJ_RELEASE_ID} /* Release */,")
pbx.append("\t\t\t);")
pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
pbx.append("\t\t\tdefaultConfigurationName = Release;")
pbx.append("\t\t};")
pbx.append("/* End XCConfigurationList section */")
pbx.append("")

pbx.append("\t};")
pbx.append(f"\trootObject = {PROJECT_ID} /* Project object */;")
pbx.append("}")

output = "\n".join(pbx)
out_path = "EbaySellerMessenger.xcodeproj/project.pbxproj"
with open(out_path, "w") as f:
    f.write(output)
print(f"Generated {out_path}")
print(f"Total Swift files: {len(SWIFT_FILES)}")
