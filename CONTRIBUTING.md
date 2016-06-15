---
---

# Getting Started website

## How to contribute?

### Table of contents

- [Your first contribution, without leaving your browser](#your-first-contribution)
- [Further contributions](#further-contributions)
- [Pictures submission](#pictures-submission)

### Your first contribution

[Sign in](https://github.com/login){:target="_blank"} to your Github account.

[On the Wakanda Studio repository](https://github.com/Wakanda/wakanda-studio){:target="_blank"}, make sure you are on the [gh-pages](https://github.com/Wakanda/wakanda-studio/tree/gh-pages){:target="_blank"} branch:

![gh-pages](img/readme-gh-pages.png)

Open the page you want to contribue to:

![open-md](img/readme-open-md-file.png)

Click on the file edition button. It will automatically fork the project in your Github account:

![fork-edit-file](img/readme-fork-edit-file.png)

Edit the file content and propose a file change:

![submit-change](img/readme-propose-file-change.png)

_**Note**: you can [edit more files](#further-contributions) before submitting a pull request._

Create a pull request:

![propose-file-change](img/readme-create-pr.png)

Add a short comment to explain the update you propose and confirm.

Thanks for your first contribution. We'll now review your submission!

### Further contributions

Open the Wakand Studio repository now forked on your Github account: `https://github.com/YOUR-USERNAME/wakanda-studio`

Choose the branch you want to work on. For example, switch to `gh-pages` (we'll create a branch later) or continue on your `patch-x` branch to edit more files:

![gh-pages](img/readme-gh-pages.png)

Open the file to edit and start a pull request and check the _create a new branch_ option.
Alternatively, you can check the _commit directly_ option to submit more commits before creating a pull request or to improve an existing one.

![new-branch-pr](img/readme-new-branch-pr.png)

### Pictures submission

You can't submit a picture via the Github web interface. So, let's use the command line:

Clone your wakanda-studio fork:

    $ git clone https://github.com/YOUR-USERNAME/wakanda-studio.git
    $ cd wakanda-studio

Switch to the `gh-pages` branch:

    $ git checkout origin/gh-pages -t

Add your image in the `img` folder of wakanda-studio. And commit your update:

    $ git add img/readme-propose-file-change.png
    $ git commit -m "Add propose file change screenshot for README"
  
Push your local changes on `gh-pages` to a new remote branch. For example, `readme-screenshot-propose`:

    $ git push origin gh-pages:readme-screenshot-propose

Open the Wakand Studio repository forked on your Github account: `https://github.com/YOUR-USERNAME/wakanda-studio`

Your new branch is ready for a pull request! Click on _Compare & pull request_:

 ![pushed-branch-pr](img/readme-pushed-branch-pr.png)

Make sure the _base branch_ is `gh-pages`:

 ![open-pull-request](img/readme-open-pull-request.png)

Add a short comment to explain the update you propose and confirm. Thank you again!