# Zira

### This is a simple, easy-to-use tool for JIRA.
### The tool based on JIRA REST API and fully written on Swift

#### There is a list of available arguments and theirs parameters
* `install` - initiate authorization and setting process. No parameters
* `createIssue` - creating issue. Parameters: -summary, summary of issue, -description, description of issue, -type, type of issue, make sure you specify the correct type by enter command `issueTypes`, -parent, name of parent issue if you specify this parameter it requires correct issue type. Example:
     `zira createIssue -summary "Issue's summary" -description "Issue's description" -type Sub-Task -parent "PROJ-1"`
* `editIssue` - for now this parameter able to change issue's status. Parameters: -issue, Issue's name like "PROJ-12", -status, New status. Pay attention and specify correct status. You can get all available statuses by command `zira issueStatuses`
* `issueTypes` - output all available issue types
* `issueStatuses` - output all available issue statuses
