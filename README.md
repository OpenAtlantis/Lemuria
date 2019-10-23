# Lemuria

This is the Lemuria nested windowing toolkit on which Atlantis is built, updated so that it will compile properly on Xcode 10 and later.

When using this repository, after the first checkout, you will want to be in the root of the repo and run the following command:

```
git config --local include.path ../.gitconfig
```

This will include the repository git configuration, which (at present) only defines a git commit template. (The reason for the `..` is that the include path is relative to the `.git` configuration directory.)