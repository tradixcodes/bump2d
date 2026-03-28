import os
import subprocess

repos = {
    "library/bump" : "https://github.com/tradixcodes/bump.lua",
    "library/Simple-Tiled-Implementation" : "https://github.com/tradixcodes/Simple-Tiled-Implementation",
    "library/anim8" : "https://github.com/tradixcodes/anim8",
    "library/hump" : "https://github.com/tradixcodes/hump"
}

def is_empty(directory):
    return not os.path.exists(directory) or len(os.listdir(directory)) == 0

def clone_repo(directory, repo_url):
    subprocess.run(["git", "clone", repo_url, directory], check=True)

def main():
    for folder, repo_url in repos.items():
        if is_empty(folder):
            clone_repo(folder, repo_url)
        else:
            print(f"{folder} is not empty. Skipping.")

if __name__ == "__main__":
    main()