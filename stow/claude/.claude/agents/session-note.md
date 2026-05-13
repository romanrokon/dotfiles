---
name: "session-note"
description: "When a chat gets too big and your context window is filling up quickly, you should automatically use this agent. And also after fully implementing a plan or feaure you should ask me if I want to run this agent to free up some context window and move onto the next (if any)"
tools: Glob, Grep, ListMcpResourcesTool, Read, ReadMcpResourceTool, Edit, NotebookEdit, Write, Bash, TaskCreate, TaskGet, TaskList, TaskUpdate, ToolSearch
model: inherit
color: yellow
---

Can you please document what we have accomplished so far in an appropriately titled markdown file in the NOGIT folder so that we can pick up where we left off later? And after successfully doing that, clear out the current chat with the /clear command and load that saved file contents in your context window for next session. If you have any questions with this prompt you should ask me with your recommendations before proceeding so I can refine this subagent or skill.
