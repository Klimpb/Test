import java.io.*;
import java.util.regex.*;
import java.net.*;
import java.util.*;

public class TeamData {
	Hashtable<String, String> config = new Hashtable<String, String>();
	Hashtable<String, String> players = new Hashtable<String, String>();

	HttpURLConnection conn;

	String NoDataID = "0";
	String DataID = "0";
	String bracket = "5";
	String teamPage = "1";
	String teamName = "";

	String regexFileSep = "\\\\";

	int TotalPlayers = 0;
	int NeedingUpdate = 0;

	Hashtable<String, String> armories = new Hashtable<String, String>();

	Long cutOffTime = System.currentTimeMillis() - ( 60 * 60 * 24 * 7 ) * 1000;

	public TeamData() throws Exception {
		armories.put( "us", "http://armory.worldofwarcraft.com/" );
		armories.put( "eu", "http://armory.wow-europe.com/" );
		armories.put( "kr", "http://armory.worldofwarcraft.co.kr/" );

		String fileSeparator = System.getProperty( "file.separator" );
		if( fileSeparator.equals( "\\" ) ) {
			regexFileSep = "\\\\";
		} else {
			regexFileSep = fileSeparator;
		}

		ParseConfig();
		CheckConfig();

		LoadPlayers();

		BufferedReader in = new BufferedReader( new InputStreamReader( System.in ) );
		while( true ) {
			System.out.print( "Action [reconfig/player/search/teams/status/unknown/update/exit]: " );

			String line = in.readLine();

			if( line.equals( "reconfig" ) ) {
				config.clear();
				CheckConfig();

			} else if( line.equals( "unknown" ) ) {
				CheckUnknown();
				SavePlayers();
				LoadPlayers();

			} else if( line.equals( "status" ) ) {
				CheckStatus();

			} else if( line.equals( "player" ) ) {
				FindPlayer();

			} else if( line.equals( "teams" ) ) {
				if( !config.containsKey( "teams" ) ) {
					UnlockTeams();
					System.out.println();
				}

				if( config.containsKey( "teams" ) ) {
					while( true ) {
						System.out.print( "Choose a bracket [2/3/5]: " );
						line = in.readLine();

						if( line.equals( "5" ) || line.equals( "3" ) || line.equals( "2" ) ) {
							bracket = line;
							break;
						}
					}


					System.out.print( "Choose the page number [1]: " );
					line = in.readLine();

					if( line.equals( "" ) ) {
						teamPage = "1";
					} else {
						teamPage = line;
					}

					RequestTeams();

					SavePlayers();
					LoadPlayers();
				}

			} else if( line.equals( "update" ) ) {
				UpdatePlayers();
				SavePlayers();
				LoadPlayers();

			} else if( line.equals( "search" ) ) {
				while( true ) {
					System.out.print( "Choose a bracket [2/3/5]: " );
					line = in.readLine();

					if( line.equals( "5" ) || line.equals( "3" ) || line.equals( "2" ) ) {
						bracket = line;
						break;
					}
				}

				while( true ) {
					System.out.print( "Enter team name to search: " );
					line = in.readLine();

					if( !line.equals( "" ) ) {
						teamName = line;
						break;
					}
				}


				SearchTeam();
				SavePlayers();
				LoadPlayers();

			} else if( line.equals( "exit" ) ) {
				SavePlayers();
				SaveConfig();
				break;
			}

			System.out.println();
		}
	}

	public void SearchTeam() throws Exception {
		System.out.println( "Search for " + teamName + " on " + config.get( "battlegroup" ) + " " + bracket + "vs" + bracket );

		for( int page=1; page <= 100; page++ ) {
			System.out.print( "Searching page " + page + "..." );

			URL url = new URL( config.get( "armory" ) + "arena-ladder.xml?b=" + config.get( "battlegroup" ) + "&ts=" + bracket + "&p=" + page );
			conn = ( HttpURLConnection ) url.openConnection();
			conn.setRequestProperty( "User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1" );

			if( conn.getResponseCode() != 200 ) {
				System.out.println( "ERR Response code wasn't 200 OK, got " + conn.getResponseCode() + " " + conn.getResponseMessage() );
				System.out.println();
			}

			InputStream is = conn.getInputStream();
			StringBuffer sb = new StringBuffer();
			int count = 0;

			while( ( count = is.read() ) != -1 ) {
				sb.append( ( char ) count );
			}

			is.close();
			conn.disconnect();

			Matcher match;
			Pattern arenaTeam = Pattern.compile( "arenaTeam battleGroup=\"(.+?)\" faction=\"(.+?)\" factionId=\"(.+?)\" gamesPlayed=\"(.+?)\" gamesWon=\"(.+?)\" lastSeasonRanking=\"(.+?)\" name=\"(.+?)\" ranking=\"(.+?)\" rating=\"(.+?)\" realm=\"(.+?)\" realmUrl=\"(.+?)\" relevance=\"(.+?)\" seasonGamesPlayed=\"(.+?)\" seasonGamesWon=\"(.+?)\" size=\"(.+?)\" url=\"(.+?)\"" );

			String[] lines = sb.toString().split( "\\n" );

			for( String line : lines ) {
				match = arenaTeam.matcher( line );

				if( match.find() ) {
					String name = match.group( 7 );

					if( name.toLowerCase().equals( teamName.toLowerCase() ) || name.toLowerCase().indexOf( teamName.toLowerCase() ) > -1 ) {
						System.out.println( "found" );
						System.out.println( "Located " + name + " on page " + page + ", ranking is " + match.group( 8 ) + " and rating is " + match.group( 9 ) );

						return;
					}
				}
			}

			System.out.println( "not found" );
		}
	}

	public void UnlockTeams() throws Exception {
		System.out.println( "This will enable loading of the arena teams based by scanning the arena team pages." );
		System.out.println( "Around 80-100 requests are sent out for 2vs2, 100-120 for 3vs3 and 150-170 in order to get the top 20 arena team player talents." );
		System.out.println( "Please be aware of this before you use it." );
		System.out.println();

		System.out.print( "Do you still want to unlock this? [yes/no]: " );

		BufferedReader in = new BufferedReader( new InputStreamReader( System.in ) );
		String line = in.readLine();

		if( line.equals( "yes" ) ) {
			config.put( "teams", "true" );
			SaveConfig();
		}
	}

	public void CheckStatus() throws Exception {
		System.out.println( "Total players recorded: " + TotalPlayers );
		System.out.println( "Total player talents older then 7 days: " + NeedingUpdate );
	}

	public int[] GetSavedSpec( String playerName, String playerServer ) throws Exception {
		return GetSavedSpec( playerName + "-" + playerServer );
	}

	public int[] GetSavedSpec( String playerName ) throws Exception {
		if( players.containsKey( playerName ) ) {
			String[] data = players.get( playerName ).split( ":" );

			return new int[]{ Integer.parseInt( data[0] ), Integer.parseInt( data[1] ), Integer.parseInt( data[2] ) };
		}

		return null;
	}

	public void FindPlayer() throws Exception {
		BufferedReader in = new BufferedReader( new InputStreamReader( System.in ) );

		String playerName;
		String serverName;
		String line;

		while( true ) {
			System.out.print( "Player Name: " );
			line = in.readLine();

			if( !line.equals( "" ) ) {
				playerName = line;
				break;
			}
		}

		System.out.print( "Realm Name [" + config.get( "server" ) + "]: " );
		line = in.readLine();

		if( !line.equals( "" ) ) {
			serverName = line;
		} else {
			serverName = config.get( "server" );
		}


		int status = GetPlayerSpec( playerName, serverName );

		if( status == 1 ) {
			int[] spec = GetSavedSpec( playerName, serverName );
			System.out.println( playerName + "-" + serverName + ": " + spec[0] + "/" + spec[1] + "/" + spec[2] );
		} else if( status == 2 ) {
			System.out.println( "ERR " + playerName + "-" + serverName + " / " + conn.getResponseCode() + " " + conn.getResponseMessage() );
		} else if( status == 3 ) {
			System.out.println( "ERR " + playerName + "-" + serverName + " no player found." );
		} else {
			System.out.println( "ERR Requesting data for " + playerName + "-" + serverName );
		}
	}

	public void GetArenaTeam( int row, String rank, String rating, String teamName, String teamRealm, String battlegroup, String bracket ) throws Exception {
		System.out.println( "#" + rank + " (" + row + "/20), " +  rating + ", " + teamRealm + ", " + teamName );

		URL url = new URL( config.get( "armory" ) + "team-info.xml?r=" + teamRealm.replaceAll( " ", "+" ) + "&b=" + battlegroup + "&ts=" + bracket + "&t=" + teamName.replaceAll( " ", "+" ) );
		conn = ( HttpURLConnection ) url.openConnection();
		conn.setRequestProperty( "User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1" );

		if( conn.getResponseCode() != 200 ) {
			System.out.println( " - ERR Response code wasn't 200 OK, got " + conn.getResponseCode() + " " + conn.getResponseMessage() );
			System.out.println();
		}

		InputStream is = conn.getInputStream();
		StringBuffer sb = new StringBuffer();
		int count = 0;

		while( ( count = is.read() ) != -1 ) {
			sb.append( ( char ) count );
		}

		is.close();
		conn.disconnect();

		Matcher match;
		Pattern character = Pattern.compile( "character battleGroup=\"(.+?)\" charUrl=\"(.+?)\" class=\"(.+?)\" classId=\"(.+?)\" gamesPlayed=\"(.+?)\" gamesWon=\"(.+?)\" gender=\"(.+?)\" genderId=\"(.+?)\" guildId=\"(.+?)\" name=\"(.+?)\" race=\"(.+?)\" raceId=\"(.+?)\" realm=\"(.+?)\" seasonGamesPlayed=\"(.+?)\" seasonGamesWon=\"(.+?)\" teamRank=\"(.+?)\"" );

		String[] lines = sb.toString().split( "\\n" );

		int totalPlayers = 0;
		int skippedPlayers = 0;
		int errorPlayers = 0;

		for( String line : lines ) {
			match = character.matcher( line );
			if( match.find() ) {
				String playerName = match.group( 10 );
				String playerServer = match.group( 13 );

				if( players.containsKey( playerName + "-" + playerServer ) ) {
					String[] data = players.get( playerName + "-" + playerServer ).split( ":" );

					if( Long.parseLong( data[3] ) > cutOffTime ) {
						totalPlayers++;
						skippedPlayers++;
						continue;
					}
				}

				int status = GetPlayerSpec( playerName, playerServer );

				if( status == 1 ) {
					totalPlayers++;

					int[] spec = GetSavedSpec( playerName, playerServer );
					System.out.println( " - " + playerName + " (" + spec[0] + "/" + spec[1] + "/" + spec[2] + ")" );

				} else if( status == 2 ) {
					errorPlayers++;
					System.out.println( " - ERR " + playerName + " / " + conn.getResponseCode() + " " + conn.getResponseMessage() );

				} else if( status == 3 ) {
					errorPlayers++;
					System.out.println( " - ERR " + playerName + " doesn't seem to exist anymore" );

				} else {
					errorPlayers++;
					System.out.println( " - ERR Requesting data for " + playerName );
				}
			}
		}

		if( totalPlayers == skippedPlayers && errorPlayers == 0 ) {
			System.out.println( " - All players have been updated within 7 days." );
		}

		System.out.println();
	}

	public void RequestTeams() throws Exception {
		System.out.println( "Requesting the arena teams for " + config.get( "battlegroup" ) + " " + bracket + "vs" + bracket + " on page #" + teamPage );
		System.out.println();

		URL url = new URL( config.get( "armory" ) + "arena-ladder.xml?b=" + config.get( "battlegroup" ) + "&ts=" + bracket + "&p=" + teamPage );
		conn = ( HttpURLConnection ) url.openConnection();
		conn.setRequestProperty( "User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1" );

		if( conn.getResponseCode() != 200 ) {
			System.out.println( "ERR Response code wasn't 200 OK, got " + conn.getResponseCode() + " " + conn.getResponseMessage() );
			System.out.println();
		}

		InputStream is = conn.getInputStream();
		StringBuffer sb = new StringBuffer();
		int count = 0;

		while( ( count = is.read() ) != -1 ) {
			sb.append( ( char ) count );
		}

		is.close();
		conn.disconnect();

		Matcher match;
		Pattern arenaTeam = Pattern.compile( "arenaTeam battleGroup=\"(.+?)\" faction=\"(.+?)\" factionId=\"(.+?)\" gamesPlayed=\"(.+?)\" gamesWon=\"(.+?)\" lastSeasonRanking=\"(.+?)\" name=\"(.+?)\" ranking=\"(.+?)\" rating=\"(.+?)\" realm=\"(.+?)\" realmUrl=\"(.+?)\" relevance=\"(.+?)\" seasonGamesPlayed=\"(.+?)\" seasonGamesWon=\"(.+?)\" size=\"(.+?)\" url=\"(.+?)\"" );

		String[] lines = sb.toString().split( "\\n" );
		int row = 0;

		for( String line : lines ) {
			match = arenaTeam.matcher( line );

			if( match.find() ) {
				row++;
				GetArenaTeam( row, match.group( 8 ), match.group( 9 ), match.group( 7 ), match.group( 10 ), config.get( "battlegroup" ), bracket );
			}
		}
	}

	public void UpdatePlayers() throws Exception {
		System.out.println( "Updating the first 30 players that are out of date by more then 7 days." );

		int i=1;
		for( Enumeration enume = players.keys(); enume.hasMoreElements(); ) {
			String playerName = ( String ) enume.nextElement();
			String[] data = players.get( playerName ).split( ":" );

			Long updateTime = Long.parseLong( data[3] );

			if( i > 30 ) {
				break;
			}

			if( updateTime <= cutOffTime ) {
				int status = GetPlayerSpec( playerName );

				if( status == 1 ) {
					int[] spec = GetSavedSpec( playerName );
					System.out.println( "[" + i + "/30] " + playerName + " (" + spec[0] + "/" + spec[1] + "/" + spec[2] + ")" );
				} else if( status == 2 ) {
					System.out.println( "[" + i + "/30] ERR " + playerName + " / " + conn.getResponseCode() + " " + conn.getResponseMessage() );
				} else if( status == 3 ) {
					System.out.println( "[" + i + "/30] ERR " + playerName + " doesn't seem to exist anymore" );
					i--;
				} else {
					System.out.println( "[" + i + "/30] ERR Requesting data for " + playerName );
				}

				i++;
			}
		}

		if( i == 1 ) {
			System.out.println( "No players need to be updated." );
		}
	}

	public void SavePlayers() throws Exception {
		FileWriter fw = new FileWriter( new File( config.get( "path" ) + "/Interface/" + config.get( "addons" ) + "/ArenaEnemyInfo/Data.lua" ) );
		fw.write( "AEI_DataID = " + DataID + "\r\n" );
		fw.write( "AEI_Data = {\r\n" );

		for( Enumeration enume = players.keys(); enume.hasMoreElements(); ) {
			String playerName = ( String ) enume.nextElement();
			String[] data = players.get( playerName ).split( ":" );

			fw.write( " [\"" + playerName + "\"] = \"" + data[0] + ":" + data[1] + ":" + data[2] + ":" + data[3] + "\",\r\n" );
		}

		fw.write( "}" );
		fw.close();
	}

	public void LoadPlayers() throws Exception {
		File file = new File( config.get( "path" ) + "/Interface/" + config.get( "addons" ) + "/ArenaEnemyInfo/Data.lua" );
		file.createNewFile();

		BufferedReader br = new BufferedReader( new FileReader( file ) );

		String line;
		String openConfig = "";

		Matcher match;
		Pattern playerMatch = Pattern.compile( "\\[\"(.+?)\"\\] = \"(.+?)\"," );

		NeedingUpdate = 0;
		TotalPlayers = 0;

		while( ( line = br.readLine() ) != null ) {
			if( line.matches( "AEI_DataID = ([0-9]+)" ) ) {
				DataID = line.substring( 13 );

			} else if( line.matches( "AEI_Data = \\{" ) ) {
				openConfig = "data";

			} else if( line.equals( "}" ) ) {
				openConfig = "";

			} else if( openConfig.equals( "data" ) ) {
				match = playerMatch.matcher( line );
				if( match.find() && match.groupCount() == 2 ) {
					String data = match.group( 2 );

					players.put( match.group( 1 ), data );
					TotalPlayers++;

					String[] info = data.split( ":" );
					if( Long.parseLong( info[3] ) < cutOffTime ) {
						NeedingUpdate++;
					}
				}
			}
		}

		if( DataID == null ) {
			DataID = "0";
		}
	}

	public int GetPlayerSpec( String playerName ) throws Exception {
		String[] playerInfo = playerName.split( "-", 3 );

		return GetPlayerSpec( playerInfo[0], playerInfo[1] );
	}

	public int GetPlayerSpec( String playerName, String playerRealm ) throws Exception {
		URL url = new URL( config.get( "armory" ) + "character-sheet.xml?r=" + playerRealm.replaceAll( " ", "+" ) + "&n=" + playerName.replaceAll( " ", "+" ) );
		conn = ( HttpURLConnection ) url.openConnection();
		conn.setRequestProperty( "User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1" );

		// Connection issue
		if( conn.getResponseCode() != 200 ) {
			return 2;
		}

		InputStream is = conn.getInputStream();
		StringBuffer sb = new StringBuffer();
		int count = 0;

		while( ( count = is.read() ) != -1 ) {
			sb.append( ( char ) count );
		}

		is.close();
		conn.disconnect();

		Pattern talents = Pattern.compile( "<talentSpec treeOne=\"([0-9]+)\" treeThree=\"([0-9]+)\" treeTwo=\"([0-9]+)\"/>" );
		Matcher match = talents.matcher( sb.toString() );

		// Found match, update record
		if( match.find() ) {
			players.put( playerName + "-" + playerRealm, match.group( 1 ) + ":" + match.group( 3 ) + ":" + match.group( 2 ) + ":" + System.currentTimeMillis() );
			return 1;

		// They don't exist anymore (deleted/moved servers/changed names)
		} else {
			players.remove( playerName + "-" + playerRealm );
			return 3;
		}
	}

	public void CheckUnknown() throws Exception {
		File file = new File( config.get( "path" ) + "/WTF/Account/" + config.get( "account" ) + "/SavedVariables/ArenaEnemyInfo.lua" );
		if( !file.exists() ) {
			System.out.println( "It appears that you don't have anything saved yet, did you remember to do a /console reloadui" );
			return;
		}

		BufferedReader br = new BufferedReader( new FileReader( file ) );

		String line;
		int playersLogged = 0;

		Vector<String> unknownPlayers = new Vector<String>();

		Matcher match;
		Pattern dataMatch = Pattern.compile( "\"(.+?)\", -- \\[[0-9]+\\]" );

		while( ( line = br.readLine() ) != null ) {
			if( line.matches( "AEI_NoDataID = ([0-9]+)" ) ) {
				NoDataID = line.substring( 15 );

			} else {
				match = dataMatch.matcher( line );
				if( match.find() ) {
					String name = match.group( 1 );

					if( !players.containsKey( name ) ) {
						unknownPlayers.add( name );
						playersLogged++;
					}
				}
			}
		}

		if( NoDataID == null ) {
			NoDataID = "0";
		}


		if( playersLogged == 0 || NoDataID.equals( DataID ) ) {
			System.out.println( "You do not have any unknown players and do not need to do a request." );
			System.out.println( "Remember, you must do a /console reloadui before new unknown players are saved." );
			return;
		}

		System.out.println( "Found " + playersLogged + " unknown players" );
		int i = 0;

		for( Enumeration enume = unknownPlayers.elements(); enume.hasMoreElements(); ) {
			i++;

			String playerName = ( String ) enume.nextElement();
			int status = GetPlayerSpec( playerName );

			if( status == 1 ) {
				int[] spec = GetSavedSpec( playerName );
				System.out.println( "[" + i + "/" + playersLogged + "] " + playerName + " (" + spec[0] + "/" + spec[1] + "/" + spec[2] + ")" );
			} else if( status == 2 ) {
				System.out.println( "[" + i + "/" + playersLogged + "] ERR " + playerName + " / " + conn.getResponseCode() + " " + conn.getResponseMessage() );
			} else if( status == 3 ) {
				System.out.println( "[" + i + "/" + playersLogged + "] ERR " + playerName + " doesn't seem to exist anymore" );
			} else {
				System.out.println( "[" + i + "/" + playersLogged + "] ERR Requesting data for " + playerName );
			}
		}

		DataID = NoDataID;
	}

	public void ParseConfig() throws Exception {
		File file = new File( "./TeamConfig.txt" );
		file.createNewFile();

		BufferedReader br = new BufferedReader( new FileReader( file ) );
		config = new Hashtable<String, String>();

		String line;
		while( ( line = br.readLine() ) != null ) {
			String[] data = line.split( "=", 2 );
			config.put( data[0], data[1] );
		}

		if( config.containsKey( "top20" ) ) {
			config.put( "teams", "true" );
			config.remove( "top20" );
		}
	}

	public void CheckConfig() throws Exception {
		if( config.containsKey( "armory" ) ) {
			return;
		}

		System.out.println( "We will attempt to auto detect some settings, if you're fine with our option just hit ENTER." );
		System.out.println();

		String line;
		BufferedReader in = new BufferedReader( new InputStreamReader( System.in ) );


		String path = Pattern.compile( regexFileSep + "Interface" + regexFileSep + "AddOns" + regexFileSep + "ArenaEnemyInfo", Pattern.CASE_INSENSITIVE ).matcher( ( new File( "./" ) ).getCanonicalPath() ).replaceAll( "" );
		File dir = new File( path + "/Interface" );

		for( String file : dir.list() ) {
			if( file.equalsIgnoreCase( "addons" ) ) {
				config.put( "addons", file );
				break;
			}
		}

		while( true ) {
			System.out.print( "Path to World of Warcraft [" + path + "]: " );

			line = in.readLine();
			if( line.equals( "" ) ) {
				line = path;
			}

			if( !( new File( line ) ).exists() ) {
				System.out.println( "Cannot find the path " + line );
			} else {
				config.put( "path", line );
				break;
			}
		}

		dir = new File( config.get( "path" ) + "/WTF/Account" );
		while( true ) {
			System.out.print( "Account Name [" + dir.listFiles()[0].getName() + "]: " );
			line = in.readLine();

			if( line.equals( "" ) ) {
				config.put( "account", dir.listFiles()[0].getName() );
				break;

			} else if( ( new File( config.get( "path" ) + "/WTF/Account/" + line.toUpperCase() ) ).exists() ) {
				config.put( "account", line );
				break;

			} else {
				System.out.println( "No account name " + line + " found inside WTF/Account/" );
			}
		}

		BufferedReader br = new BufferedReader( new FileReader( config.get( "path" ) + "/WTF/Config.wtf" ) );
		String lang = "us";
		String server = "";

		while( ( line = br.readLine() ) != null ) {
			if( line.equals( "SET realmList \"us.logon.worldofwarcraft.com\"" ) ) {
				lang = "us";

			} else if( line.equals( "SET realmList \"eu.logon.worldofwarcraft.com\"" ) ) {
				lang = "eu";

			} else if( line.equals( "SET realmList \"kr.logon.worldofwarcraft.com\"" ) ) {
				lang = "kr";

			} else if( line.matches( "SET realmName \"(.+?)\"" ) ) {
				server = line.substring( 15, line.length() - 1 );
			}
		}

		System.out.print( "Enter the armory URL [" + armories.get( lang ) + "]" );
		line = in.readLine();

		if( line.equals( "" ) ) {
			config.put( "armory", armories.get( lang ) );
		} else {
			config.put( "armory", line );
		}

		System.out.print( "Enter your server name [" + server + "]: " );
		line = in.readLine();

		if( line.equals( "" ) ) {
			config.put( "server", server );
		} else {
			config.put( "server", line );
		}

		System.out.println( "Requesting battlegroups..." );

		URL url = new URL( config.get( "armory" ) + "battlegroups.xml" );
		conn = ( HttpURLConnection ) url.openConnection();
		conn.setRequestProperty( "User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1" );

		InputStream is = conn.getInputStream();
		StringBuffer sb = new StringBuffer();
		int count = 0;

		while( ( count = is.read() ) != -1 ) {
			sb.append( ( char ) count );
		}

		is.close();
		conn.disconnect();

		Matcher match;
		Pattern groupMatch = Pattern.compile( "battlegroup display=\"(.+?)\" name=\"(.+?)\" sortPosition=\"(.+?)\"" );
		Pattern realmMatch = Pattern.compile( "realm name=\"(.+?)\" nameEN=\"(.+?)\"" );

		Hashtable<String, String> servers = new Hashtable<String, String>();
		Hashtable<String, String> battlegroups = new Hashtable<String, String>();

		String[] lines = sb.toString().split( "\\n" );
		String displayGroup = "";
		String groupName = "";

		for( String text : lines ) {
			match = groupMatch.matcher( text );

			if( match.find() ) {
				displayGroup = match.group( 1 );
				groupName = match.group( 2 );

				battlegroups.put( groupName, displayGroup );
			}

			if( !groupName.equals( "" ) ) {
				match = realmMatch.matcher( text );

				if( match.find() ) {
					servers.put( match.group( 1 ), groupName );
				}
			}
		}

		if( servers.containsKey( config.get( "server" ) ) ) {
			System.out.print( "Enter your battlegroup [" + battlegroups.get( servers.get( config.get( "server" ) ) ) + "]: " );

			line = in.readLine();

			if( !line.equals( "" ) ) {
				config.put( "battlegroup", line );
			} else {
				config.put( "battlegroup", servers.get( config.get( "server" ) ) );
			}
		} else {
			System.out.println( "Cannot find your battlegroup." );

			while( true ) {
				System.out.print( "Enter your battlegroup: " );
				line = in.readLine();

				if( line.equals( "" ) ) {
					config.put( "battlegroup", line );
					break;
				}
			}
		}

		SaveConfig();

		System.out.println( "Done!" );
	}

	public void SaveConfig() throws Exception {
		FileWriter fw = new FileWriter( new File( "./TeamConfig.txt" ) );
		for( Enumeration enume = config.keys(); enume.hasMoreElements(); ) {
			String key = ( String ) enume.nextElement();
			String value = config.get( key );

			fw.write( key + "=" + value + "\r\n" );
		}

		fw.close();
	}

	public static void main( String[] args ) {
		try {
			new TeamData();
		} catch( Exception e ) {
			System.out.println( e );
		}
	}
}