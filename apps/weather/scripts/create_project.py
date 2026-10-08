#!/usr/bin/env python3
"""Create a dependency-free Xcode project with app, unit, and UI test targets."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent
objects = {}


def identifier(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def add(object_name, **values):
    key = identifier(object_name)
    objects[key] = values
    return key


def serialize(value):
    if isinstance(value, dict):
        return "{\n" + "\n".join(f"{key} = {serialize(item)};" for key, item in value.items()) + "\n}"
    if isinstance(value, list):
        return "(" + ", ".join(serialize(item) for item in value) + ")"
    return json.dumps(str(value))


app_id = identifier("WeatherSix-target")
products = []
groups = []
targets = []
common = {
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "5.0",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "CODE_SIGN_STYLE": "Automatic",
    "TARGETED_DEVICE_FAMILY": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "CURRENT_PROJECT_VERSION": "1",
    "PRODUCT_NAME": "$(TARGET_NAME)",
}

for name, product_type, extension in [
    ("WeatherSix", "application", "app"),
    ("WeatherSixTests", "bundle.unit-test", "xctest"),
    ("WeatherSixUITests", "bundle.ui-testing", "xctest"),
]:
    group = add(name + "-group", isa="PBXFileSystemSynchronizedRootGroup", path=name, sourceTree="<group>")
    groups.append(group)
    product = add(name + "-product", isa="PBXFileReference", explicitFileType="wrapper.application" if extension == "app" else "wrapper.cfbundle", path=f"{name}.{extension}", sourceTree="BUILT_PRODUCTS_DIR")
    products.append(product)
    phases = [add(name + "-" + phase, isa="PBX" + phase + "BuildPhase", buildActionMask="2147483647", files=[], runOnlyForDeploymentPostprocessing="0") for phase in ["Sources", "Frameworks", "Resources"]]
    configs = []
    for configuration in ["Debug", "Release"]:
        settings = dict(common, PRODUCT_BUNDLE_IDENTIFIER=f"com.yinyueyang.{name.lower()}")
        settings.update({"SWIFT_OPTIMIZATION_LEVEL": "-Onone" if configuration == "Debug" else "-O", "DEBUG_INFORMATION_FORMAT": "dwarf" if configuration == "Debug" else "dwarf-with-dsym"})
        if configuration == "Debug":
            settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG $(inherited)"
            settings["ENABLE_TESTABILITY"] = "YES"
        if name == "WeatherSix":
            settings.update({
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "INFOPLIST_KEY_CFBundleDisplayName": "Weather",
                "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
                "INFOPLIST_KEY_UIStatusBarStyle": "UIStatusBarStyleLightContent",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
                "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription": "Weather uses your location to show your local forecast when you choose Use Current Location.",
            })
        elif name == "WeatherSixTests":
            settings.update({"TEST_HOST": "$(BUILT_PRODUCTS_DIR)/WeatherSix.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/WeatherSix", "BUNDLE_LOADER": "$(TEST_HOST)"})
        else:
            settings["TEST_TARGET_NAME"] = "WeatherSix"
        configs.append(add(name + "-" + configuration, isa="XCBuildConfiguration", buildSettings=settings, name=configuration))
    config_list = add(name + "-configs", isa="XCConfigurationList", buildConfigurations=configs, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")
    dependencies = []
    if name != "WeatherSix":
        proxy = add(name + "-proxy", isa="PBXContainerItemProxy", containerPortal=identifier("project"), proxyType="1", remoteGlobalIDString=app_id, remoteInfo="WeatherSix")
        dependencies.append(add(name + "-dependency", isa="PBXTargetDependency", target=app_id, targetProxy=proxy))
    targets.append(add(name + "-target", isa="PBXNativeTarget", buildConfigurationList=config_list, buildPhases=phases, buildRules=[], dependencies=dependencies, fileSystemSynchronizedGroups=[group], name=name, productName=name, productReference=product, productType="com.apple.product-type." + product_type))

product_group = add("products", isa="PBXGroup", children=products, name="Products", sourceTree="<group>")
main_group = add("main", isa="PBXGroup", children=groups + [product_group], sourceTree="<group>")
project_configs = [add("project-" + configuration, isa="XCBuildConfiguration", buildSettings={"ALWAYS_SEARCH_USER_PATHS": "NO", "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES", "GCC_WARN_UNUSED_VARIABLE": "YES"}, name=configuration) for configuration in ["Debug", "Release"]]
project_list = add("project-configs", isa="XCConfigurationList", buildConfigurations=project_configs, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")
project_id = add("project", isa="PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "2700", "TargetAttributes": {target: {"CreatedOnToolsVersion": "27.0"} for target in targets}}, buildConfigurationList=project_list, compatibilityVersion="Xcode 16.0", developmentRegion="en", hasScannedForEncodings="0", knownRegions=["en", "zh-Hans", "Base"], mainGroup=main_group, productRefGroup=product_group, projectDirPath="", projectRoot="", targets=targets, preferredProjectObjectVersion="77")
project_dir = ROOT / "WeatherSix.xcodeproj"
scheme_dir = project_dir / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + serialize({"archiveVersion": "1", "classes": {}, "objectVersion": "77", "objects": objects, "rootObject": project_id}) + "\n")


def reference(name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{identifier(name + "-target")}" BuildableName="{name}.{"app" if name == "WeatherSix" else "xctest"}" BlueprintName="{name}" ReferencedContainer="container:WeatherSix.xcodeproj"/>'


(scheme_dir / "WeatherSix.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference("WeatherSix")}</BuildActionEntry></BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{reference("WeatherSixTests")}</TestableReference><TestableReference skipped="NO">{reference("WeatherSixUITests")}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{reference("WeatherSix")}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">{reference("WeatherSix")}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(f"Created {project_dir}")
