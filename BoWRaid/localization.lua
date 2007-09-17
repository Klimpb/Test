BWRVersion = "1.4.4";

------------
-- ENGLISH
------------

BWR_BOWRAID = "BWRaid";

-- Misc
BWR_RAID_OPEN = "*** RAID OPEN ***";

BWR_CONFIG_UPDATED = "BoW Raid configuration updated to %s!";

BWR_BW_RESET = "BigWig module reset, by %s.";

BWR_DEAD = "Dead";
BWR_OFFLINE = "Offline";

-- Admin messages
BWR_CANNOT_PERFORM = "You cannot perform this action because BoWRaid is turned off.";

BWR_NOPERMISSIONS = "You do not have the required permissions to perform this action.";

BWR_NO_INFO = "You did not pass anything, please check the help list for what this command requires.";
BWR_NO_NAME = "You need to enter a name to perform this action.";

BWR_IN_RAID = "You are already inside a raid and cannot form another.";
BWR_NOT_IN_RAID = "You must be inside a raid group to use this.";

BWR_SENDING_PING = "Sending version ping, this may take a few seconds.";
BWR_RELEASE_REQUESTED = "%s has requested you auto release.";
BWR_LOGOUT_REQUESTED = "%s has started a force logout.";

BWR_FORCE_LOGOUT_SENT = "Sent force logout request to %s";
BWR_FORCE_RELEASE_SENT = "Sent force release request to %s.";

BWR_REPORT_SENT = "Report request for the last %s seconds sent to %s. The overlay will popup with the report as it comes.";

BWR_RELEASE_RECEIVED = "<BWRaid> Release received.";
BWR_LOGOUT_RECEIVED = "<BWRaid> Logout received.";

BWR_FORCE_LOGGED = "You we're force logged out by %s.";

-- Cooldown request/display
BWR_REQUESTING_CD = "Request time left on the ability %s.";

BWR_COOLDOWNUP_ROW = "%s: Ready";
BWR_COOLDOWN_ROW = "%s: %s";

-- Other whisper triggers, these shouldn't be translated.
BWR_TRIG_RELEASE = "[BW] AUTORELEASE";
BWR_TRIG_ACCEPTINVITE = "[BW] ACCEPTINVITE";
BWR_TRIG_LOGOUT = "[BW] AUTOLOGOUT";

-- Whisper triggers
BWR_TRIG_LEADER = "leader";
BWR_TRIG_ASSIST = "assist";
BWR_TRIG_ASSISTANT = "assistant";
BWR_TRIG_INVITE = "invite";

-- Auto-invite errors
BWR_YOU_ARE_GROUPED = "<BWRaid> You are already grouped.";
BWR_PARTY_FULL = "<BWRaid> Party is full.";
BWR_RAID_FULL = "<BWRaid> Raid is full.";

-- Regular commands
BWR_HELP_CMD = {};
BWR_HELP_CMD[1] = "/bwraid - Pull up the configuration window";
BWR_HELP_CMD[2] = "/ma <1-10> - Assist the current main assist for the number passed, you can skip the <1-10> entry and it'll just default to main assist #1";
BWR_HELP_CMD[3] = "/listma - Lists the current main assist";
BWR_HELP_CMD[4] = "/raidshow - Shows the raid frames";
BWR_HELP_CMD[5] = "/raidhide - Hides the raid frames";
BWR_HELP_CMD[6] = "/report <raid/party/guild/officer/console/channel name> <time> - Report your attacks/heals taken history";
BWR_HELP_CMD[7] = "/bwradmin - List the admin commands";
BWR_HELP_CMD[8] = "/rfcorrupt - Checks for raid frame corruption, stuff like clicking one name and getting a different person";

-- Admin commands
BWR_ADMIN_CMD = {};
BWR_ADMIN_CMD[1] = "Most of these require assist or leader to perform.";
BWR_ADMIN_CMD[2] = "/setma <1-10> <name> - Set the main assist, you can skip the <1-10> entry and it'll just default to setting main assist #1.";
BWR_ADMIN_CMD[3] = "/clearma <1-10> - Clears the currently set main assist for whatever number you enter. Skip the <1-10> entry to clear all of them.";
BWR_ADMIN_CMD[4] = "/raidform <name> <yes/no> - Name of a person to invite, convert to raid, set FFA loot and give assist, second option is to display the raid open message in guild, default is no.";
BWR_ADMIN_CMD[5] = "/resetbw - Resets all active BigWig's modules for everyone";
BWR_ADMIN_CMD[6] = "/frelease <name> - Requests the specific user to auto-release, they must be running BoWRaid 1.2.3 or higher.";
BWR_ADMIN_CMD[7] = "/bwping - Sends a version ping and will respond with the version that everyone is running.";
BWR_ADMIN_CMD[8] = "/reqreport <name> <timeBack> - Requests a report for the timeBack entered from the player you choose, they must be running BoWRaid 1.2.7 or later.";
BWR_ADMIN_CMD[9] = "/flogout <name> - Requests the specific user to logout, they must be running BoWRaid 1.3.3 or higher, and will be logged out after 20 seconds.";

-- UI
BWR_TAB_GENERAL = "General";
BWR_TAB_FRAME = "Frames";
BWR_TAB_ASSIST = "Assist";
BWR_TAB_RAID = "Raid";
BWR_TAB_BUFF = "Buffs";
BWR_TAB_GROUPS = "Show Groups";
BWR_TAB_CLASSES = "Show Classes";
BWR_TAB_ALERT = "Alerts";
BWR_TAB_RANGE = "Range Check";
BWR_TAB_HEALTH = "Health Bars";

-- General
BWR_UI_AUTOLEADER = "Auto leader/assist";
BWR_UI_AUTOINVITE = "Auto invite";
BWR_UI_BLOCKSPAM = "Block spam";
BWR_UI_HIDEWORLDMAP = "Hide world map icon";

BWR_UI_HIDEWORLDMAP_TT = "Hide the world map minimap icon.";
BWR_UI_AUTOLEADER_TT = "Automatically gives leader when whispered 'leader' and assistant when whispered 'assist'";
BWR_UI_AUTOINVITE_TT = "Automatically invites players who whisper you 'invite', must either be leader, assistant or not grouped.";
BWR_UI_BLOCKSPAM_TT = "Blocks BoWRaid whisper spam, this is stuff like group is full or you are already grouped.";

-- Assist
BWR_UI_ENABLEASSIST = "Enable main assist frames";
BWR_UI_ENABLEMATARGET = "Show main assist target";
BWR_UI_ENABLEMATARGETTARGET = "Show main assist targets target";

-- Frame
BWR_UI_LOCKFRAME = "Lock frames";
BWR_UI_BGCOLOR = "Background Color";
BWR_UI_BORDERCOLOR = "Border Color";
BWR_UI_BGOPACITY = "Background Opacity (%d%%)";
BWR_UI_BORDEROPACITY = "Border Opacity (%d%%)";
BWR_UI_FRAMESCALE = "Scale (%d%%)";
BWR_UI_LOCKFRAME_TT = "Locks all BoWRaid frames.";

-- Raid frames
BWR_UI_DEFAULT = "Default";
BWR_UI_BLIZZARD = "Blizzard";

BWR_UI_HEALTHLOST = "Health Difference";
BWR_UI_HEALTHPERCENT = "Health Percent";
BWR_UI_HEALTHCRT = "Health Current";
BWR_UI_HEALTHCRTTL = "Health Crt + Ttl";

BWR_UI_ENABLEFRAME = "Auto-open raid frames";
BWR_UI_SHOWRANK = "Show rank";
BWR_UI_GROUPCLASS = "Auto-group class frames";
BWR_UI_GROUPRAID = "Auto-group group frames";
BWR_UI_ROWS = "Class/Group frames per a row";
BWR_UI_PADDING = "Raid member row spacing";
BWR_UI_FRAMESTYLE = "Raid frame style";
BWR_UI_SHOWCOUNT = "Show frame row count on title";
BWR_UI_CHECKCORRUPT = "Auto-check frame corruption";

BWR_UI_CHECKCORRUPT_TT = "Automatically checks for frame corruption whenever you leave combat, this is done silently you wont see anything even if corruption is fixed.";
BWR_UI_SHOWCOUNT_TT = "Shows how many people are being displayed in a group frame on the title, so instead of Warrior you'd see Warrior (8).";
BWR_UI_FRAMESTYLE_TT = "Format to display the raid frames in.\nDefault will show the names and the health/mana bars on the same line.\nBlizzard shows the names above health/mana.";
BWR_UI_ENABLEFRAME_TT = "Automatically opens the raid frames when you join a raid group.\n\nYou can manually open or close them using /raidshow or /raidhide using either of these will skip the auto-open option however until you log out.";
BWR_UI_SHOWRANK_TT = "Shows the players rank next to there name, leader is shown as '(L)' and assistant is shown as '(A)'.";
BWR_UI_GROUPCLASS_TT = "Groups the class frames using the frames per a row option.";
BWR_UI_GROUPRAID_TT = "Groups the group frames using the frames per a row option.";
BWR_UI_ROWS_TT = "How many class/group frames per a row, for example in a 40 man raid setting this to 4 will show 2 rows of 4 each, setting it to 1 will show 8 columns.";
BWR_UI_PADDING_TT = "This allows you change the spacing between members in the raid frames, maximum is 7, minimum is 0.\n\nSetting padding below 6 will only allow you to display 2 (de)buffs on both sides.";

-- Health bars
BWR_UI_HEALTHONLY = "Health only bars";
BWR_UI_LARGERHEALTHONLY = "Larger health bars";
BWR_UI_HEALTHDISPLAY = "Health text display";
BWR_UI_HEALTHCOLOR = "Health text color";

BWR_UI_HEALTHDISPLAY_TT = "The display mode for health text, requires health only bars to be enabled.\n\nDifference shows how much health they lost, 10,000 total health and only 8,000 currently will show -2,000.\nPercent will just show a percentage of how much health they have.\nCurrent will display how much health they currently have.\nCrt + Ttl will display current and health total.";
BWR_UI_HEALTHONLY_TT = "Increases the size of the health bars on the raid frames and hides the mana bars.";
BWR_UI_LARGERHEALTHONLY_TT = "Increases the size of the health only bars even more.";

-- Buffs
BWR_UI_BUFF = "Show Buffs";
BWR_UI_DEBUFF = "Show Debuffs";
BWR_UI_HOT = "Show HoTs";
BWR_UI_NONE = "None";

BWR_UI_BUFFTYPE_LEFT = "Left buff display type";
BWR_UI_BUFFTYPE_RIGHT = "Right buff display type";
BWR_UI_SHOWCURABLE = "Show only curable debuffs";
BWR_UI_SHOWCASTABLE = "Show only buffs you can cast";
BWR_UI_SHOWUNIQUE = "Show unique debuffs/buffs/hots";

BWR_UI_BUFFTYPE_LEFT_TT = "What buff or debuffs to display on the left side of the raid frames, if you choose two of the same type on both sides then the left side will show (de)buffs 1 through 4, and the right side will show (de)buffs 5 through 8.\n\nUsing HoT's as a display type will show Rejuvenation, Renew, Regrowth and Lifebloom, if you have show castable on it'll only show HoT's you can cast.";
BWR_UI_BUFFTYPE_RIGHT_TT = "What buff or debuffs to display on the right side of the raid frames, if you choose two of the same type on both sides then the left side will show (de)buffs 1 through 4, and the right side will show (de)buffs 5 through 8.\n\nUsing HoT's as a display type will show Rejuvenation, Renew, Regrowth and Lifebloom, if you have show castable on it'll only show HoT's you can cast.";
BWR_UI_SHOWCURABLE_TT = "Only displays debuffs you can cure, if you're displaying debuffs.";
BWR_UI_SHOWCASTABLE_TT = "Only displays buffs you can cast, if you are displaying buffs or hots.";
BWR_UI_SHOWUNIQUE_TT = "Only displays unique buffs filtered out by name, this means that things like multiple hot's on the same person will only show the first one and skip the rest.";

-- Range
BWR_UI_ENABLERANGE = "Enable range check";
BWR_UI_RANGETYPE = "Range check type";

BWR_UI_HEAL = "Heal (40y)";
BWR_UI_DECURSE = "Decurse (30y)";

BWR_UI_ENABLERANGE_TT = "Dims out people who are to far away from you using the range check type.\n\nThis only works for Priests, Paladins, Druids, Shamans and Mages.";
BWR_UI_RANGETYPE_TT = "Spell type to check range on, if you're a mage then heal will disable range check.";

-- Alerts
BWR_UI_ALERTENABLE = "Enable alerts";
BWR_UI_DEBUFFCOLOR = "Debuff background color by debuff type";
BWR_UI_CURECOLOR = "Debuff background color";
BWR_UI_ALERTCURE = "Show alert on curable debuff";
BWR_UI_HPCOLOR = "Health background color";
BWR_UI_ALERTHP = "Show alert when health is below (percent)";
BWR_UI_ALERTDEBUFF = "Show alert on debuff";

BWR_UI_DEBUFFCOLOR_TT = "Colors the background using the debuff type, if the debuff is uncurable, then the background is red, the color is the first debuff it finds meaning if somebody has a magic, disease and a poison it'll show the color for magic.";
BWR_UI_ALERTCURE_TT = "Shows an alert when a debuff you can cure afflicts a raid member.";
BWR_UI_ALERTDEBUFF_TT = "Shows an alert when a player is debuffed, this is any debuff and not just curable ones.";
BWR_UI_ALERTHP_TT = "Shows an alert when a raid members health drops below the entered percent.\n\You can enter 0 to disable.";

BWR_UI_CURECOLOR_TT = "Backgrond color when a player is afflicted by a curable debuff, note that this color takes priority over health and will override it if they have a curable debuff and health below the threshold.";
BWR_UI_HPCOLOR_TT = "Background color when a players health is below the threshold.";

-- Show group/class
BWR_UI_SHOWGROUP = "Show Group %s";
BWR_UI_SHOWCLASS = "Show %s";