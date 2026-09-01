import os
import subprocess
import time
import shutil

game = "Skyrim Special Edition"# "Fallout 4" or "Skyrim Special Edition"

def extract_library_folder(file_path):
    path = None
    # Open the file
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Iterate over lines to find the path section
    for line in lines:
        # If we find the path, extract it
        if '"path"' in line:
            path = line.strip().split('"')[3]
            break
    return path

# Locate game files
game_path = None
try:
    steam_path = '~/.local/share/Steam/config/libraryfolders.vdf'
    steam_path = os.path.expanduser(steam_path)
    steam_library_path = extract_library_folder(steam_path)
    game_path = os.path.join(steam_library_path, "steamapps/common", game)
    
    if os.path.exists(game_path):
        print("Found the game location: " + game_path)
    else:
        raise Exception("game path doesnt exist")
except:
    game_path = None
    print("didnt find library folder in normal steam location")

if game_path == None:
    pass
    # try flatpak steam
if game_path == None:
    print("Cannot find your game folder. You will have to find it manually")
    print("open steam, right click the game in your library, manage, Browse local files")
    print("it may look something like this: /home/YOUR NAME/.local/share/Steam/steamapps/common/" + game)
    game_path = str(input("paste game path here: "))
    if os.path.exists(game_path):
        print("Found the game location: " + game_path)
    else:
        raise Exception("game path doesnt exist")




print("This application requires your Steam account credentials to authenticate and verify ownership of", game, "for downloading necessary files.")

valid = False
while valid == False:
    try:
        username = str(input("Enter your steam username: "))
        password = str(input("Enter your steam password: "))
        valid = True
    except:
        print("not a valid password")

#move to libraries directory
libraries_dir = os.path.join(os.getcwd(), 'libraries')
os.chdir(libraries_dir)
print ("The program will now download the files from steam, this may take a while.")
time.sleep(1)

#download the files
if game == "Skyrim Special Edition":#testing hack this should be Skyrim Special Edition
    command = "./DepotDownloader -app 489830 -depot 489831 -manifest 3660787314279169352 -username " + username + " -remember-password" 
    subprocess.run(command, shell=True)
    print("Download 1 of 3 completed")

    command = "./DepotDownloader -app 489830 -depot 489832 -manifest 2756691988703496654 -username " + username
    subprocess.run(command, shell=True)
    print("Download 2 of 3 completed")

    command = "./DepotDownloader -app 489830 -depot 489833 -manifest 5291801952219815735 -username " + username
    subprocess.run(command, shell=True)
    print("Download 3 of 3 completed")
elif game == "Fallout 4":
    print ("Fallout 4 not implemented")
else:
    print("wrong game")
    #raise ValueError("Invalid game")

#move the files from depots to the game folder
source_folder_path = os.path.join(os.getcwd(), "depots")
print(source_folder_path)
