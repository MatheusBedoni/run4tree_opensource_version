// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Run4Tree';

  @override
  String splashArtCredit(String handle) {
    return 'Art by @$handle';
  }

  @override
  String get loginTaglineRunPrefix => 'Your run plants ';

  @override
  String get loginTaglineTreesHighlight => 'real trees.\n';

  @override
  String get loginTaglineOffline => 'Works 100% offline.';

  @override
  String get loginFeatureOfflineTitle => 'No internet needed';

  @override
  String get loginFeatureOfflineSubtitle => 'Track runs anywhere';

  @override
  String get loginFeatureNoSignupTitle => 'No sign-up or password';

  @override
  String get loginFeatureNoSignupSubtitle => 'Start running in seconds';

  @override
  String get loginFeaturePlantTreesTitle => 'Plant real trees';

  @override
  String get loginFeaturePlantTreesSubtitle => 'Track your real impact';

  @override
  String get loginStartButton => 'Start now';

  @override
  String get loginChipSustainable => 'SUSTAINABLE';

  @override
  String get loginChipGamified => 'GAMIFIED';

  @override
  String homeRunSavedMessage(String distance) {
    return 'Run saved! $distance km';
  }

  @override
  String get homeRunSaveErrorMessage => 'Error saving the run.';

  @override
  String get homeMapLoadingTitle => 'Let\'s plant a forest...';

  @override
  String get homeMapLoadingSubtitle => 'Getting GPS location';

  @override
  String get homeRunAdStartTitle => 'READY TO GROW';

  @override
  String get homeRunAdStartSubtitle =>
      'Your ads become seeds — 10 seeds plant one real tree.';

  @override
  String get homeRunAdFinishTitle => 'GREAT WORK!';

  @override
  String get homeRunAdFinishSubtitle =>
      'Saving your activity while this ad turns into seeds.';

  @override
  String get homeRunAdLoopWatch => 'AD';

  @override
  String get homeRunAdLoopSeeds => 'SEEDS';

  @override
  String get homeRunAdLoopTree => 'REAL TREE';

  @override
  String homeRunAdSeedsToNextTree(int accumulated, int total) {
    return '$accumulated/$total seeds to your next tree';
  }

  @override
  String homeRunAdSeedsGainedBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count seeds',
      one: '+1 seed',
    );
    return '$_temp0';
  }

  @override
  String homeRunAdSeedsEarnedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count SEEDS EARNED',
      one: '+1 SEED EARNED',
    );
    return '$_temp0';
  }

  @override
  String get homeRunAdRewardTitle => 'SEEDS EARNED';

  @override
  String get homeRunAdRewardSubtitle =>
      'This ad\'s revenue just went into your next real tree.';

  @override
  String get homeRunAdRewardExplainer =>
      'Reward confirmed: the revenue from this ad was added to your tree fund.';

  @override
  String get homeRunAdTreeTitle => 'TREE COMPLETE!';

  @override
  String get homeRunAdTreeSubtitle =>
      'Your seeds filled up — a real tree is being planted for you.';

  @override
  String get homeRunAdMissedTitle => 'NO SEEDS THIS TIME';

  @override
  String get homeRunAdMissedSubtitle =>
      'Seeds only come from ads watched to the end.';

  @override
  String get homeRunAdMissedExplainer =>
      'The ad did not finish, so nothing was credited. Your next one still counts.';

  @override
  String get homeRunTreeEarnedBadge => '+1 tree';

  @override
  String get homeRunAdFooterNote =>
      'Ads are how you grow seeds — no purchase needed. Rewards verified by RevenueCat, trees planted by Tree-Nation.';

  @override
  String get homeRunAdTip1 =>
      'Ads are the only way to earn seeds — 10 seeds become one real tree.';

  @override
  String get homeRunAdTip2 =>
      'Every ad you watch waters the seedling growing in your garden.';

  @override
  String get homeRunAdTip3 =>
      'A single tree can absorb around 22 kg of CO2 every year.';

  @override
  String get homeRunAdTip4 =>
      'Trees are planted by Tree-Nation, with a real certificate for each one.';

  @override
  String get homeUnitKm => 'km';

  @override
  String get homeHudTimeLabel => 'TIME';

  @override
  String get homeHudKmLabel => 'KM';

  @override
  String get homeHudPausedValue => 'PAUSED';

  @override
  String get homeHudPaceLabel => 'MIN/KM';

  @override
  String get homeHudSpeedLabel => 'KM/H';

  @override
  String get homeHudCaloriesLabel => 'KCAL';

  @override
  String get homeHudLiveLabel => 'LIVE';

  @override
  String get homeExerciseBike => 'BIKE';

  @override
  String get homeExerciseWalk => 'WALK';

  @override
  String get homeExerciseRun => 'RUN';

  @override
  String get homeStartLabel => 'START';

  @override
  String get homePauseButton => 'PAUSE';

  @override
  String get homeResumeButton => 'RESUME';

  @override
  String get homeFinishButton => 'FINISH';

  @override
  String get homeNavActivity => 'Activity';

  @override
  String get homeNavProgress => 'Progress';

  @override
  String get homeNavForest => 'Forest';

  @override
  String get homeNavProfile => 'Profile';

  @override
  String get onboardingNameTitle => 'What should we call you?';

  @override
  String get onboardingNameSubtitle =>
      'We\'ll use your name to personalize your journey on Run4Tree.';

  @override
  String get onboardingNameFieldLabel => 'Your name';

  @override
  String get onboardingAgeTitle => 'What\'s your age?';

  @override
  String get onboardingAgeSubtitle =>
      'This helps us calibrate goals and metrics that fit you better.';

  @override
  String get onboardingBodyTitle => 'Weight and height';

  @override
  String get onboardingBodySubtitle =>
      'We use this data to estimate calories and track your progress.';

  @override
  String get onboardingGoalTitle => 'What\'s your weekly goal?';

  @override
  String get onboardingGoalSubtitle =>
      'How many kilometers do you want to run per week? You can adjust this later.';

  @override
  String get onboardingContinueButton => 'Continue';

  @override
  String get onboardingFinishButton => 'Finish';

  @override
  String get onboardingSaveErrorMessage =>
      'We couldn\'t save your data. Please try again.';

  @override
  String get fieldLabelAge => 'Age';

  @override
  String get fieldLabelWeight => 'Weight';

  @override
  String get fieldLabelHeight => 'Height';

  @override
  String get fieldLabelWeeklyGoal => 'Weekly goal';

  @override
  String get suffixYears => 'years';

  @override
  String get suffixKg => 'kg';

  @override
  String get suffixCm => 'cm';

  @override
  String get suffixKm => 'km';

  @override
  String get commonRetryButton => 'Try again';

  @override
  String profileAgeMemberSince(int age, String date) {
    return '$age years old · member since $date';
  }

  @override
  String get profileEditButton => 'Edit profile';

  @override
  String get profileGoalCompletedMessage => 'This week\'s goal is complete! 🎉';

  @override
  String get profileTreesLabel => 'Trees';

  @override
  String get profileTotalKmLabel => 'total km';

  @override
  String get profileRunsLabel => 'Runs';

  @override
  String get profileBodyDataTitle => 'Body data';

  @override
  String get profileBmiLabel => 'BMI';

  @override
  String get profileLoadErrorMessage =>
      'We couldn\'t load your profile. Please try again.';

  @override
  String get profileSaveErrorMessage =>
      'We couldn\'t save your changes. Please try again.';

  @override
  String get profileLegalSectionTitle => 'Legal & About';

  @override
  String get profileHowWePlantTreesButton => 'How We Plant Real Trees';

  @override
  String get profileTermsButton => 'Terms of Service';

  @override
  String get profilePrivacyButton => 'Privacy Policy';

  @override
  String get profileLicensesButton => 'Open Source Licenses';

  @override
  String weeklyGoalProgressLabel(String current, String goal) {
    return '$current / $goal km';
  }

  @override
  String get editProfileNameFieldLabel => 'Name';

  @override
  String get editProfileSaveButton => 'Save changes';

  @override
  String get exercisesEmptyTitle => 'No runs recorded yet';

  @override
  String get exercisesEmptySubtitle =>
      'Start a run on the main screen to see your history here.';

  @override
  String get exercisesLabelBike => 'Bike';

  @override
  String get exercisesLabelWalk => 'Walk';

  @override
  String get exercisesLabelRun => 'Run';

  @override
  String get exercisesLoadErrorMessage =>
      'We couldn\'t load your runs. Please try again.';

  @override
  String get exercisesKcalUnit => 'kcal';

  @override
  String get exercisesHistoryTitle => 'History';

  @override
  String get exercisesRecordsTitle => 'Records';

  @override
  String get exercisesStatisticsTitle => 'Statistics';

  @override
  String get exercisesSectionMore => 'More';

  @override
  String get exercisesFilterAll => 'All';

  @override
  String get exercisesRecordLongestDistance => 'Longest distance';

  @override
  String get exercisesRecordLongestDuration => 'Longest duration';

  @override
  String get exercisesRecordMostCalories => 'Most kcal burned';

  @override
  String get exercisesRecordBestPace => 'Best pace';

  @override
  String get exercisesRecordTopSpeed => 'Top speed';

  @override
  String get exercisesRecordsEmptyMessage =>
      'Finish your first activity to unlock records.';

  @override
  String get exercisesAllRecordsTitle => 'All records';

  @override
  String exercisesChartDistanceTitle(int months) {
    return 'Distance (km) - last $months months';
  }

  @override
  String get exercisesMonthlyBreakdownTitle => 'Month by month';

  @override
  String get exercisesStatsEmptyMessage =>
      'No activities recorded in this period.';

  @override
  String get exercisesSummaryActivities => 'Activities';

  @override
  String get exercisesSummaryDuration => 'Duration';

  @override
  String get exercisesSummaryDistance => 'Distance';

  @override
  String get exercisesUnitKm => 'km';

  @override
  String get exercisesUnitKmh => 'km/h';

  @override
  String get exercisesUnitPerKm => '/km';

  @override
  String get exercisesUnitHour => 'h';

  @override
  String get exercisesUnitMinute => 'min';

  @override
  String get gardenTitle => 'Your Garden';

  @override
  String get gardenSubtitle => 'Watch ads to plant real trees.';

  @override
  String gardenTreesPlanted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trees planted',
      one: 'tree planted',
    );
    return '$_temp0';
  }

  @override
  String get gardenNextTreeLabel => 'Next tree';

  @override
  String gardenSeedsProgress(int accumulated, int total) {
    return '$accumulated/$total seeds';
  }

  @override
  String get gardenLoadErrorMessage => 'We couldn\'t load your progress.';

  @override
  String get gardenWatchAdErrorMessage => 'We couldn\'t play the ad right now.';

  @override
  String get gardenAdDismissedMessage =>
      'Ad closed before finishing — watch it to the end to earn the seed.';

  @override
  String get gardenAdUnavailableMessage =>
      'No ad available right now. Please try again shortly.';

  @override
  String get gardenAdRewardErrorMessage =>
      'We couldn\'t confirm the reward. Please try again.';

  @override
  String get gardenWatchAdButton => 'Watch ad and earn a seed';

  @override
  String get gardenCo2CompensatedLabel => 'CO2 compensated';

  @override
  String gardenCo2CompensatedValue(String kg) {
    return '$kg kg';
  }

  @override
  String get gardenForestTitle => 'Your forest';

  @override
  String get gardenForestEmptyMessage =>
      'No trees planted yet. Watch ads to plant your first one.';

  @override
  String get gardenViewCertificate => 'View certificate';

  @override
  String get gardenCertificateOpenError =>
      'We couldn\'t open the certificate link.';

  @override
  String get gardenGlobalForestButton => 'See the Global Forest';

  @override
  String get globalForestPageTitle => 'Global Forest';

  @override
  String get globalForestSubtitle =>
      'Every tree earned in Run4Tree — and the people celebrating them.';

  @override
  String globalForestTotalLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trees planted by everyone',
      one: 'tree planted by everyone',
    );
    return '$_temp0';
  }

  @override
  String get globalForestRecentTitle => 'Recently planted';

  @override
  String get globalForestEmptyMessage =>
      'No trees published yet. Be the first to plant one!';

  @override
  String get globalForestUnavailableMessage =>
      'The Global Forest is unavailable right now. Please try again later.';

  @override
  String get exercisesDetailsPace => 'Avg. Pace';

  @override
  String get exercisesDetailsAvgSpeed => 'Avg. Speed';

  @override
  String get exercisesDetailsMaxSpeed => 'Max Speed';

  @override
  String get exercisesDetailsElevationGain => 'Elevation Gain';

  @override
  String get exercisesDetailsElevationLoss => 'Elevation Loss';

  @override
  String get exercisesDetailsMaxElevation => 'Max Elevation';

  @override
  String get exercisesDetailsDehydration => 'Dehydration';

  @override
  String get exercisesDetailsSeedsEarned => 'Seeds Earned';

  @override
  String get exercisesDetailsStartTime => 'Start Time';

  @override
  String exercisesDetailsDistance(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String get exercisesDetailsDuration => 'Duration';

  @override
  String get exercisesDetailsCalories => 'Calories';

  @override
  String get runCompletedTitle => 'Run completed!';

  @override
  String runCompletedSubtitle(int trees) {
    return 'Great job planting $trees trees';
  }

  @override
  String get runCompletedShareButton => 'Share';

  @override
  String runCompletedShareSummary(
    Object calories,
    Object distance,
    Object duration,
    Object exercise,
    Object pace,
    Object speed,
  ) {
    return '$exercise • $distance km\n\n⏱️ $duration\n🔥 $calories kcal\n⚡ Avg. speed: $speed km/h\n📍 Avg. pace: $pace min/km';
  }

  @override
  String get shareRunTitle => 'Share your progress';

  @override
  String get shareRunFormatStory => 'Stories';

  @override
  String get shareRunFormatSquare => 'Square';

  @override
  String get shareRunTabPhoto => 'Photo';

  @override
  String get shareRunTabMap => 'Map';

  @override
  String get shareRunTabColor => 'Color';

  @override
  String get shareRunTabSticker => 'Sticker';

  @override
  String get shareRunPhotoAdd => 'Add';

  @override
  String get shareRunPhotoCamera => 'Take a photo';

  @override
  String get shareRunPhotoGallery => 'Choose from gallery';

  @override
  String get shareRunPhotoError => 'We couldn\'t open that photo.';

  @override
  String get shareRunMapLight => 'Light';

  @override
  String get shareRunMapSatellite => 'Satellite';

  @override
  String get shareRunMapDark => 'Dark';

  @override
  String get shareRunMapCartoon => 'Run4Tree';

  @override
  String get shareRunColorForest => 'Forest';

  @override
  String get shareRunColorSunrise => 'Sunrise';

  @override
  String get shareRunColorNight => 'Night';

  @override
  String get shareRunColorTransparent => 'Transparent';

  @override
  String get shareRunStickerNone => 'None';

  @override
  String get shareRunStickerHint => 'Drag the sticker to move it';

  @override
  String get shareRunNoRoute =>
      'This activity has no GPS route to show on a map.';

  @override
  String get shareRunExportError =>
      'We couldn\'t create the image. Please try again.';

  @override
  String get shareRunCaptionFooter =>
      'Every km I move helps plant real trees 🌳 #Run4Tree';

  @override
  String get shareCardDistance => 'Distance';

  @override
  String shareCardSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count seeds for real trees',
      one: '+1 seed for real trees',
    );
    return '$_temp0';
  }

  @override
  String get shareCardTagline => 'Moving for a greener planet';

  @override
  String get stickerCollectionTitle => 'Sticker collection';

  @override
  String stickerCollectionProgress(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get stickerCollectionHint =>
      'Tap an unlocked sticker to make it your avatar and your marker on the map.';

  @override
  String get stickerCollectionInUse => 'In use';

  @override
  String get stickerCollectionUseButton => 'Use as avatar';

  @override
  String get stickerCollectionLockedLabel => 'Locked';

  @override
  String get stickerCollectionLockedMessage =>
      'Keep moving to unlock this one.';

  @override
  String get stickerCollectionLoadError => 'Could not load your stickers.';

  @override
  String get stickerUnlockedTitle => 'New sticker unlocked!';

  @override
  String stickerUnlockedSubtitle(String name) {
    return '$name just joined your collection.';
  }

  @override
  String get stickerUnlockedUseButton => 'Use as avatar';

  @override
  String get stickerUnlockedCloseButton => 'Nice!';

  @override
  String get profileStickersSectionTitle => 'Your collection';

  @override
  String get profileStickersCardTitle => 'Stickers';

  @override
  String profileStickersCardSubtitle(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get profileAvatarChangeHint => 'Tap your avatar to change it';

  @override
  String get stickerRequirementFree => 'Yours from day one';

  @override
  String stickerRequirementTotalDistance(String target) {
    return 'Cover $target km in total';
  }

  @override
  String stickerRequirementSingleRun(String target) {
    return 'Cover $target km in a single activity';
  }

  @override
  String stickerRequirementStreak(int target) {
    return 'Move $target days in a row';
  }

  @override
  String stickerRequirementTrees(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: 'Plant $target trees',
      one: 'Plant your first tree',
    );
    return '$_temp0';
  }

  @override
  String stickerRequirementRuns(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: 'Finish $target activities',
      one: 'Finish your first activity',
    );
    return '$_temp0';
  }

  @override
  String stickerRequirementWeeklyGoal(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: 'Hit your weekly goal $target weeks',
      one: 'Hit your weekly goal once',
    );
    return '$_temp0';
  }

  @override
  String stickerRequirementNightRuns(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: 'Work out $target times after 8 PM',
      one: 'Work out once after 8 PM',
    );
    return '$_temp0';
  }

  @override
  String get stickerRequirementVariety =>
      'Try all three activities: walk, run and bike';

  @override
  String stickerNameFallback(String id) {
    return 'Sticker #$id';
  }

  @override
  String get stickerName1 => 'Dawn Swallow';

  @override
  String get stickerName2 => 'Monarch';

  @override
  String get stickerName3 => 'Hawk Moth';

  @override
  String get stickerName4 => 'Tiger Moth';

  @override
  String get stickerName5 => 'Katydid';

  @override
  String get stickerName6 => 'Golden Moth';

  @override
  String get stickerName7 => 'Horned Beetle';

  @override
  String get stickerName8 => 'Apollo Butterfly';

  @override
  String get stickerName9 => 'Honeybee';

  @override
  String get stickerName10 => 'Tree Climber';

  @override
  String get stickerName11 => 'Ladybug';

  @override
  String get stickerName12 => 'Garden Spider';

  @override
  String get stickerName13 => 'Emerald Caterpillar';

  @override
  String get stickerName14 => 'Dragonfly';

  @override
  String get profileEnvironmentalEducationButton => 'Environmental Education';

  @override
  String get educationPageTitle => 'Environmental Education';

  @override
  String get educationForestsTitle => 'The Importance of Forests';

  @override
  String get educationForestsBody =>
      'Forests are the lungs of our planet. They purify the air we breathe, filter the water we drink, and provide habitat for over 80% of terrestrial biodiversity. By planting trees, we help restore these vital ecosystems and support the communities that depend on them.';

  @override
  String get educationGlobalWarmingTitle => 'Global Warming & Risks';

  @override
  String get educationGlobalWarmingBody =>
      'Global temperatures have risen by approximately 1.1°C since the pre-industrial era, leading to extreme weather, rising sea levels, and loss of biodiversity. Without significant action to reduce emissions, we risk irreversible damage to our planet\'s climate systems.';

  @override
  String get educationCo2Title => 'The Role of CO2';

  @override
  String get educationCo2Body =>
      'Carbon dioxide (CO2) is the primary greenhouse gas driving climate change. Human activities release over 35 billion tons of CO2 into the atmosphere each year. Trees play a critical role in mitigating this by absorbing CO2 and storing carbon in their trunks, branches, and roots.';

  @override
  String get homeCommunityButtonLabel => 'GROUP';

  @override
  String get homeCommunityBadge => 'NEW';

  @override
  String get communityPageTitle => 'Group Challenge';

  @override
  String get communityHeroTitle => 'Plant trees together';

  @override
  String get communityHeroSubtitle =>
      'Exercise together: every group workout grows the group\'s forest and climbs the ranking.';

  @override
  String get communityCurrentChallengeTitle => 'Current challenge';

  @override
  String get communityNoChallengeTitle => 'No active challenge yet';

  @override
  String get communityNoChallengeBody =>
      'A new group challenge is coming soon. Stay tuned!';

  @override
  String get communityComingSoon => 'COMING SOON';

  @override
  String get communitySeedsLabel => 'Seeds';

  @override
  String get communityTreesLabel => 'Trees';

  @override
  String get communityParticipantsLabel => 'Participants';

  @override
  String get communityJoinButton => 'Join challenge';

  @override
  String get communityHowItWorksTitle => 'How it works';

  @override
  String get communityStepJoinTitle => 'Join a challenge';

  @override
  String get communityStepJoinBody =>
      'Each challenge runs for a limited time with a shared goal.';

  @override
  String get communityStepWatchTitle => 'Exercise with your group';

  @override
  String get communityStepWatchBody =>
      'Start exercises from the group. Their ads add seeds to the group\'s forest, and every exercise counts in the ranking.';

  @override
  String get communityStepPlantTitle => 'Plant real trees';

  @override
  String get communityStepPlantBody =>
      'When the group reaches the goal, real trees are planted. Your personal runs are not affected.';

  @override
  String communitySeedsProgress(int collected, int goal) {
    return '$collected / $goal seeds';
  }

  @override
  String communityTimeLeftDays(int count) {
    return '${count}d left';
  }

  @override
  String communityTimeLeftHours(int count) {
    return '${count}h left';
  }

  @override
  String communityTimeLeftMinutes(int count) {
    return '${count}m left';
  }

  @override
  String communityRealTreesPlanted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count real trees already planted by this group',
      one: '1 real tree already planted by this group',
    );
    return '$_temp0';
  }

  @override
  String get communityGoalReached => 'Goal reached! Thank you, team.';

  @override
  String get communityJoinedLabel => 'You\'re in this group!';

  @override
  String get communityJoinError =>
      'Couldn\'t join the challenge. Check your connection and try again.';

  @override
  String get communityParticipantsTitle => 'Ranking';

  @override
  String get communityNoParticipants =>
      'No one here yet. Be the first to join!';

  @override
  String get communityParticipantFallbackName => 'Runner';

  @override
  String get communityYouTag => 'YOU';

  @override
  String get communityStartExerciseButton => 'Start a group exercise';

  @override
  String get communityGroupExerciseCaption =>
      'Every group exercise counts in the ranking. Its ads grow the group\'s forest, verified by RevenueCat.';

  @override
  String get communityExercisesLabel => 'Exercises';

  @override
  String communityParticipantWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String communityParticipantMinutes(int count) {
    return '$count min';
  }

  @override
  String communityWorkoutCounted(String group) {
    return 'Exercise counted for $group!';
  }

  @override
  String get communityWorkoutTooShort =>
      'This exercise was too short to count in the ranking.';

  @override
  String get communityWorkoutFailed =>
      'Couldn\'t record this exercise in the group. Check your connection.';

  @override
  String get homeGroupExerciseLabel => 'GROUP EXERCISE';

  @override
  String get homeGroupExerciseHint => 'Counts in the group ranking';

  @override
  String get homeGroupExerciseCancel => 'Exercise solo instead';

  @override
  String homeRunAdGroupRewardSubtitle(String group) {
    return 'Verified by RevenueCat and added to $group\'s forest.';
  }

  @override
  String get homeRunAdGroupTreeTitle => 'GROUP TREE GROWN!';

  @override
  String homeRunAdGroupTreeSubtitle(String group) {
    return '$group gathered enough seeds for another tree.';
  }

  @override
  String get homeRunAdGroupRewardExplainer =>
      'In group exercises, ad seeds go to the group\'s forest instead of your personal tree.';

  @override
  String get pushPromptTitle => 'Know the moment your tree is planted';

  @override
  String get pushPromptBodyGroup =>
      'We\'ll tell you when your group plants a real tree — with the species and the country — and when the ranking changes.';

  @override
  String get pushPromptBodyExercise =>
      'We\'ll tell you the moment your seeds become a real tree, with the species, the country and the certificate.';

  @override
  String get pushPromptAccept => 'Turn on notifications';

  @override
  String get pushPromptLater => 'Not now';

  @override
  String get gardenPendingTreeTitle => 'On its way 🌱';

  @override
  String gardenPendingTreeBody(int number) {
    return 'Tree #$number is yours. We\'ll notify you when it\'s planted and the certificate is ready.';
  }

  @override
  String get gardenPendingTreeStatus => 'Planting in progress';

  @override
  String communityTreesPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more trees secured, on their way',
      one: '1 more tree secured, on its way',
    );
    return '$_temp0';
  }

  @override
  String get feedTitle => 'Latest trees';

  @override
  String get feedAnonymousAuthor => 'A Run4Tree runner';

  @override
  String get feedTreeTitle => 'A new tree was earned';

  @override
  String feedMyTreeTitle(int number) {
    return 'Your tree #$number';
  }

  @override
  String feedGroupTreeTitle(String group) {
    return '$group earned a tree';
  }

  @override
  String get feedGroupFallback => 'A group';

  @override
  String get feedPlantingInProgress => '🌱 Planting in progress';

  @override
  String get feedShareMyTree => 'Celebrate this tree';

  @override
  String get feedActionDelete => 'Delete my post';

  @override
  String get feedActionReport => 'Report post';

  @override
  String get feedActionHideAuthor => 'Hide posts from this person';

  @override
  String get feedPlantingDetails => 'Planting details';

  @override
  String get feedDetailsPending =>
      'This tree is secured and on its way. The species, the place and the certificate show up here as soon as it\'s in the ground.';

  @override
  String get feedDetailsSpecies => 'Species';

  @override
  String get feedDetailsCountry => 'Country';

  @override
  String get feedDetailsProject => 'Project';

  @override
  String get feedDetailsCo2 => 'CO₂';

  @override
  String feedDetailsCo2Value(int kg) {
    return '$kg kg over its lifetime';
  }

  @override
  String get feedDeleteConfirm =>
      'Delete your message? The tree stays in the Global Forest.';

  @override
  String get feedDeleted => 'Your message was deleted.';

  @override
  String get feedReportConfirm =>
      'Report this post? We\'ll review it, and it disappears if others report it too.';

  @override
  String get feedReported => 'Thanks — the post was reported.';

  @override
  String get feedAuthorHidden =>
      'You won\'t see posts from this person anymore.';

  @override
  String get feedCancel => 'Cancel';

  @override
  String get feedConfirm => 'Confirm';

  @override
  String get feedTimeNow => 'now';

  @override
  String feedTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String feedTimeHours(int hours) {
    return '$hours h';
  }

  @override
  String feedTimeDays(int days) {
    return '$days d';
  }

  @override
  String get feedErrorAlreadyPosted => 'You\'ve already celebrated this tree.';

  @override
  String get feedErrorAlreadyReported => 'You\'ve already reported this post.';

  @override
  String get feedErrorRateLimited =>
      'That\'s a lot of posts! Try again in a little while.';

  @override
  String get feedErrorInvalidMessage =>
      'Write a message of up to 280 characters.';

  @override
  String get feedErrorNotAllowed =>
      'This action isn\'t available for this post.';

  @override
  String get feedErrorGeneric =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get feedComposeTitle => 'Celebrate your tree';

  @override
  String feedComposeSubtitle(int number) {
    return 'Tell everyone about tree #$number. Only people who plant a tree can post here.';
  }

  @override
  String get feedComposeStickerLabel => 'Pick a sticker from your collection';

  @override
  String get feedComposeHint => 'My first tree! 🌳';

  @override
  String feedComposePostingAs(String name) {
    return 'Posting as $name';
  }

  @override
  String get feedComposePostingAnonymous => 'Posting without a name';

  @override
  String get feedComposeRules =>
      'Keep it kind. Posts can be reported and removed.';

  @override
  String get feedComposePublish => 'Post to the Global Forest';

  @override
  String get feedUpdatesOptInTitle => 'Tell me when others plant 🌍';

  @override
  String get feedUpdatesOptInBody =>
      'At most one notification now and then, when people celebrate new trees.';

  @override
  String celebrationTitle(int number) {
    return 'Tree #$number is yours! 🎉';
  }

  @override
  String get celebrationTitleNoNumber => 'A new tree is yours! 🎉';

  @override
  String get celebrationPlantedBody =>
      'It\'s already in the ground, planted with the ads you watched.';

  @override
  String celebrationPlantedBodyWhere(String where) {
    return '$where — already in the ground, planted with the ads you watched.';
  }

  @override
  String get celebrationPendingBody =>
      'It\'s secured and on its way. We\'ll let you know when it\'s in the ground and the certificate is ready.';

  @override
  String get celebrationInFeed =>
      'Your tree is already in the Global Forest. Want to celebrate it with a message?';

  @override
  String get celebrationShareButton => 'Celebrate in the feed';

  @override
  String get celebrationNotNow => 'Not now';
}
