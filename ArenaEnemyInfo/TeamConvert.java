import java.io.*;
import java.util.regex.*;
import java.net.*;
import java.util.*;

public class TeamConvert {
	Hashtable<String, Long> playerTimes = new Hashtable<String, Long>();
	Hashtable<String, int[]> players = new Hashtable<String, int[]>();

	String newPath = "";
	String oldPath = "";

	public TeamConvert() throws Exception {
		CheckUpgrade();
	}

	public void SavePlayers() throws Exception {
		FileWriter fw = new FileWriter( new File( newPath + "\\Data.lua" ) );
		fw.write( "AEI_DataID = 0\r\n" );
		fw.write( "AEI_Data = {\r\n" );

		for( Enumeration enume = players.keys(); enume.hasMoreElements(); ) {
			String playerName = ( String ) enume.nextElement();
			int[] spec = players.get( playerName );

			if( playerTimes.containsKey( playerName ) ) {
				fw.write( " [\"" + playerName + "\"] = \"" + spec[0] + ":" + spec[1] + ":" + spec[2] + ":" + playerTimes.get( playerName ).toString() + "\",\r\n" );
			} else {
				fw.write( " [\"" + playerName + "\"] = \"" + spec[0] + ":" + spec[1] + ":" + spec[2] + ":" + System.currentTimeMillis() + "\",\r\n" );
			}
		}

		fw.write( "}" );
		fw.close();
	}

	public void LoadPlayers() throws Exception {
		File file = new File( oldPath + "\\ArenaSpec_Data.lua" );
		file.createNewFile();

		BufferedReader br = new BufferedReader( new FileReader( file ) );

		String line;
		String openConfig = "";

		Matcher match;
		Pattern dataMatch = Pattern.compile( "\\[\"(.+?)\"\\] = \\{ ([0-9]+), ([0-9]+), ([0-9]+) \\}," );
		Pattern timeMatch = Pattern.compile( "\\[\"(.+?)\"\\] = ([0-9]+)," );

		while( ( line = br.readLine() ) != null ) {
			if( line.matches( "ArenaSpec_Time = \\{" ) ) {
				openConfig = "time";

			} else if( line.matches( "ArenaSpec_Data = \\{" ) ) {
				openConfig = "data";

			} else if( line.equals( "}" ) ) {
				openConfig = "";

			} else if( openConfig.equals( "time" ) ) {
				match = timeMatch.matcher( line );

				if( match.find() && match.groupCount() == 2 ) {
					Long updatedTime = Long.parseLong( match.group( 2 ) );
					playerTimes.put( match.group( 1 ), updatedTime );
				}

			} else if( openConfig.equals( "data" ) ) {
				match = dataMatch.matcher( line );
				if( match.find() && match.groupCount() == 4 ) {
					players.put( match.group( 1 ), new int[]{ Integer.parseInt( match.group( 2 ) ), Integer.parseInt( match.group( 3 ) ), Integer.parseInt( match.group( 4 ) ) } );
				}
			}
		}
	}

	public void CheckUpgrade() throws Exception {
		String fileSeparator = System.getProperty( "file.separator" );
		String regexFileSep = fileSeparator;

		if( fileSeparator.equals( "\\" ) ) {
			regexFileSep = "\\\\";
		}

		// Configuration wont exist, so auto detect everything
		String path = Pattern.compile( regexFileSep + "Interface" + regexFileSep + "AddOns" + regexFileSep + "ArenaEnemyInfo", Pattern.CASE_INSENSITIVE ).matcher( ( new File( "./" ) ).getCanonicalPath() ).replaceAll( "" );
		path = path + "\\Interface";

		File dir = new File( path );

		for( String file : dir.list() ) {
			if( file.equalsIgnoreCase( "addons" ) ) {
				path = path + "\\" + file;
				break;
			}
		}

		path = path + "\\ArenaSpec";

		dir = new File( path );

		if( !( new File( path ) ).exists() ) {
			System.out.println( "Cannot find ArenaSpec folder, no upgrade needed." );
			return;
		}

		oldPath = path;
		newPath = ( new File( "." ) ).getCanonicalPath();

		System.out.println( "Upgrading data from ArenaSpec to ArenaEnemyInfo" );
		System.out.println();

		System.out.println();
		System.out.print( "Moving saved data..." );

		File from = new File( oldPath + "\\ArenaSpec_Data.lua" );
		File dest = new File( newPath + "\\Data.lua" );

		from.renameTo( dest );

		System.out.println( "done" );

		System.out.print( "Upgrading format..." );

		LoadPlayers();
		SavePlayers();

		System.out.println( "done" );

		System.out.println( "Upgrade is complete, you can now remove the ArenaSpec/ folder." );
		System.out.println();
	}

	public static void main( String[] args ) throws Exception {
		new TeamConvert();
	}
}