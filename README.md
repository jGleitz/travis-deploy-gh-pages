# Deploy to gh-pages from Travis [![Build Status](https://travis-ci.org/jGleitz/travis-deploy-gh-pages.svg?branch=master)](https://travis-ci.org/jGleitz/travis-deploy-gh-pages)
Bash script to deploy to `gh-pages` from Travis.

## Features
- **Easy to set up**. Just add one line to your `.travis.yml` and set up your GitHub Token.
- **Language agnostic**. Because it just works on files, this script can be used for any project.
- **Branch folders**. `master`’s artifacts are put on the top level. Other branches are put into a `branches` directory. This means:
   - Deployment for all branches. If you are developing a feature in a branch, you can already have its artifacts published (and e.g. link to them from a PR)
   - Branches don’t override `master`’s artifacts. The main artifacts you link to are always from `master`
- **Secure**. The script will never print your credentials. 
  
## Usage

#### Add a github token:
1. Go to [your GitHub Token settings page](https://github.com/settings/tokens) and hit “Generate new Token”. Enable the scope `public_repo`. Copy the token.
2. Go to your Travis settings and create a new Environment variable called `GH_TOKEN`. Paste the token generated in 1. as the value. Leave “Display value in build log” switched off!

#### Add the script to your `.travis.yml`:

```yaml
after_success:
 - bash <(curl -s https://jgleitz.github.io/travis-deploy-gh-pages/deploy.sh) path/to/artifact1 path/to/artifact2
```

Replace the paths with the paths to your artifacts.

## Details
Adding the above to your `.travis.yml` will download and execute this project’s script. The script will:
 - either checkout your existing `gh-pages` branch or create a new one.
 - create a default `README.md`, linking to your GitHub Pages. You can overwrite this file by passing your own `README.md` to the script.
 - remove files checked out.
 - remove all folders in the `branches` directory corresponding to deleted branches.
 - copy in your files by passing its arguments to `rm -r`. If the build is on the `master` branch, the files will be put on the top level. Otherwise, they will be put into the `branches/$branchName` folder.
 - commit and push back to GitHub.
