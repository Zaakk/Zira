# Zira

### NAME
#### zira - Manage your JIRA

### DESCRIPTION
#### This is a simple, easy-to-use tool for JIRA.
#### The tool based on JIRA REST API and fully written on Swift

#### The following options are available:

* `install` - initiate authorization and setting process. Parameters:
  * -login 'username'
  * -pass 'password'
  * -host 'example.com'
  * -project 'project name'

If you won't set any parameter will be initiated interactive logging in process.

* `create` - creating issue. Parameters:
  * -summary, summary of issue
  * -description, description of issue
  * -type, type of issue, make sure you specify the correct type by enter command `issueTypes`
  * -parent, name of parent issue if you specify this parameter it requires correct issue type.

Example:
`zira create -summary "Issue's summary" -description "Issue's description" -type Sub-Task -parent "PROJ-1"`

* `edit` - Parameters:
  * -issue, Issue's name like "PROJ-12"
  * -status, New status
  * -assign, reassign on other user
  * -summary, issue's summary
  * -description, issue's description

Pay attention and specify correct status. You can get all available statuses by command `zira issueStatuses`.
Example:
`zira edit -summary "New summary for issue" -description "New description" -assign "MyTeamLead" -status "Fixed"`

* `issueTypes` - output all available issue types
* `issueStatuses` - output all available issue statuses

Also if you don't want to set up the program you can manually set all authorization credentials with any command. There is parameters for 'in command' authorization:

* `-login` required
* `-pass` required
* `-host` required
* `-project` not required for `editIssue` command.

