"Load and run tests to be performed by TravisCI"
| gitPath |
Transcript cr; show: 'travis---->travisCI.st'.
gitPath := (FileDirectory default directoryNamed: 'git_cache') fullName.

Gofer new
  package: 'GsUpgrader-Core';
  url: 'http://ss3.gemtalksystems.com/ss/gsUpgrader';
  load.
(Smalltalk at: #GsUpgrader) upgradeGrease.

GsDeployer deploy: [
  "Load Zinc ... "
  Metacello new
    baseline: 'ZincHTTPComponents';
    repository: 'filetree://', gitPath, '/zinc/repository';
    onLock: [:ex | ex honor ];
    load: #('CI')
].

"Run ALL tests in repository"
TravisCISuiteHarness
  value: TestCase suite
  value: 'TravisCISuccess.txt' 
  value: 'TravisCIFailure.txt'.
