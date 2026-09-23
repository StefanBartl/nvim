# Activity-Stream vom Referenzierten case

[SNOW Link](https://support-hub.tricentis.com/now/cwf/agent/record/x_ttng2_sapresolve_case/FA163EC3A29B1FD1A1A1FB176F463EB1)
[Case 888622](C:/repos/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1245018/Research/ReferencedCase_ActivityStream.md)

[1/45] 2026-08-25 06:46:21 | Comment | SAP Resolve
at: 2026-08-25 04:44:59 GMT
This case has been closed by the Customer.

----------------------------------------


[4/45] 2026-08-19 10:15:31 | Comment | David O'Keeffe
Memo to Customer, visible to SAP and customer.

Hi team, thanks for your time on the call earlier today. I'm glad we were able to find a solution to this. To summarise, in order to carry out parallel execution of multiple tests on Saucelabs:

Ensure all the modules contain the Configuration Parameter CanExecuteInParallel = True
Create a new Execution List Folder, and create the Test Configuration Parameter Execute in Parallel = True on the folder level.
Drag and drop your TestCases (i.e Samsung, Xiaomi, Google) into the Execution List folder to create individual Execution Lists for each.
Right-Click the folder and click Run to run all of the contained Execution Lists at once.

In our call, this succeeded in running all of the tests in SauceLabs.

I hope this helps. I have included some documentation below. If you have any further questions, please feel free to let me know on this ticket. Otherwise, you can close this ticket any time.

https://docs.tricentis.com/tosca-2025.1/en-us/content/engines_3.0/mobile/mobile_parallel_execution_configure_devices_and_tests.htm
https://docs.tricentis.com/tosca-2026.1/en-us/content/engines_3.0/mobile/tbox_mobileweb_set_appium_capabilities.htm
https://docs.tricentis.com/tosca-2025.1/en-us/content/tosca_commander/xmodules_properties.htm

Thank you,


----------------------------------------

[5/45] 2026-08-19 10:08:47 | Field changes | David O'Keeffe


----------------------------------------

[6/45] 2026-08-17 15:53:20 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-08-17 13:53:20 GMT
from:
There was a change in the case

----------------------------------------

[7/45] 2026-08-17 15:53:03 | Comment | Stefan Bartl
Send to Customer, updates that transfer case ownership to the customer


Thank you for your update.

Please note that we conduct our technical investigations directly within the ticket to ensure all configurations and details are fully documented. Remote sessions are reserved for cases where all required information and artifacts (such as screenshots, logs, subsets) have been provided, we have verified that the basic configuration matches the documentation, and initial troubleshooting steps have not resolved the issue.

To help you locate the Module configuration and export the subset in Tosca Commander, please follow the steps and official documentation below:

1. How to check/find the Module Configuration

1. In Tosca Commander, navigate to the Modules tab.
2. Select the Module(s) referenced inside your TestCase `Order Process_Samsung`.
3. In the Properties pane (usually on the right side), look for the parameter `CanExecuteInParallel`.
4. Ensure its value is set to `True`.
5. Please take a screenshot of this Properties pane showing the parameter set to True.

You can find more information to this topic in our documentation: Properties for XModules

2. How to export a Tosca Subset (`.tsu`)

1. In Tosca Commander, right-click on the folder or ExecutionList containing your TestCase.
2. Select Export Subset from the context menu.
3. Save the `.tsu` file and attach it to this case.

You can find more information to this topic in our documentation: Import and export subsets

If you are unable to export the subset at this time, providing the screenshot of the Module properties showing `CanExecuteInParallel = True` will be sufficient for us to perform the initial verification.

If you're interested in consulting or training, let me know and I'll connect you with the right person. Please note that these are paid services.

Looking forward to your response!

Best Regards,

Stefan Bartl
Support Specialists
SAP Partner - Tricentis

----------------------------------------

[8/45] 2026-08-17 15:53:03 | Field changes | Stefan Bartl


----------------------------------------

[9/45] 2026-08-17 15:29:27 | Work notes | Stefan Bartl

Thank you for your update.

Please note that we conduct our technical investigations directly within the ticket to ensure all configurations and details are fully documented. Remote sessions are reserved as a last resort once all required technical information and artifacts have been collected.

To help you locate the Module configuration and export the subset in Tosca Commander, please follow the steps and official documentation below:

1. How to check/find the Module Configuration:

1. In **Tosca Commander**, navigate to the **Modules** tab.
2. Select the Module(s) referenced inside your TestCase `Order Process_Samsung`.
3. In the **Properties** pane (usually on the right side), look for the parameter **`CanExecuteInParallel`**.
4. Ensure its value is set to **`True`**.
5. *Please take a screenshot of this Properties pane showing the parameter set to True.*

**You can find more information to this topic in our documentation:** [Properties for XModules](https://docs.tricentis.com/tosca-2024.2/en-us/content/tosca_commander/xmodules_properties.htm)

2. How to export a Tosca Subset (`.tsu`):

1. In **Tosca Commander**, right-click on the folder or ExecutionList containing your TestCase.
2. Select **Export Subset** from the context menu.
3. Save the `.tsu` file and attach it to this case.

**You can find more information to this topic in our documentation:** [Import and export subsets](https://docs.tricentis.com/tosca-2024.2/en-us/content/tosca_commander/import_export_subsets.htm)

If you are unable to export the subset at this time, providing the **screenshot of the Module properties** showing `CanExecuteInParallel = True` will be sufficient for us to perform the initial verification.

Looking forward to your response!

----------------------------------------

[10/45] 2026-08-14 14:45:13 | Comment | SAP Resolve
Customer added a memo
at: 2026-08-14 12:43:34 GMT

Hi Team,

we are unable to find the .tsu and module config .

Please schedule working session to check

----------------------------------------

[11/45] 2026-08-14 14:45:13 | Field changes | SAP Resolve


----------------------------------------

[12/45] 2026-08-13 10:55:13 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-08-13 08:55:13 GMT
from:
There was a change in the case

----------------------------------------

[13/45] 2026-08-13 10:54:18 | Comment | Stefan Bartl
Send to Customer, updates that transfer case ownership to the customer

Thank you for your update.

To investigate why the Parallel Block creation is still failing despite setting the parameter, we need to inspect the exact Module structure and property settings in your workspace.

Could you please provide us with the following items?

1. Screenshots of the Module Properties
- A screenshot showing the Module(s) used inside the TestCase Order Process_Samsung with the `CanExecuteInParallel` parameter clearly visible and set to `True`.
- Please ensure all Modules referenced by this TestCase have been updated.

2. Tosca Subset (`.tsu` file)
- A small exported subset containing the TestCase, its referenced Modules, and the ExecutionList.
- You can export this by right-clicking the affected folder/ExecutionList in Tosca Commander and choosing Export Subset.

Looking forward to your response!

Best regards,

Stefan Bartl
Technical Support Specialist
SAP Partner - Tricentis

----------------------------------------

[14/45] 2026-08-13 10:54:18 | Field changes | Stefan Bartl


----------------------------------------

[15/45] 2026-08-12 14:26:34 | Comment | SAP Resolve
Customer added a memo
at: 2026-08-12 12:25:21 GMT

we have set properties to true but still not working, explained issue clearly to Devid

----------------------------------------

[16/45] 2026-08-12 14:26:34 | Field changes | SAP Resolve


----------------------------------------

[17/45] 2026-08-05 11:26:15 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-08-05 09:26:14 GMT
from:
There was a change in the case

----------------------------------------

[18/45] 2026-08-05 11:26:10 | Comment | Stefan Bartl
Send to Customer, updates that transfer case ownership to the customer

Thank you for providing the updated screenshot.

Please note that this error message ("Could not create the Parallel Block because at least one selected item is not defined to be run in parallel. Item: Order Process_Samsung") points to a different underlying configuration issue.

In Tosca Commander, creating a Parallel Block requires that all Modules referenced within the selected TestCases are explicitly configured to allow parallel execution.

Could you please verify whether the configuration parameter `CanExecuteInParallel` is set to `True` for all Modules used within the TestCase Order Process_Samsung?

If this parameter is not set to `True`, please update the Module properties accordingly. The documentation links below provide details on this parameter as well as guidance on how to configure your modules for parallel execution:

- Properties for XModules
- Run tests in parallel

Please verify these configurations in your workspace before you proceed!

Best Regards,

Stefan Bartl
Support Specialists
SAP Partner - Tricentis

----------------------------------------

[19/45] 2026-08-05 11:26:10 | Field changes | Stefan Bartl


----------------------------------------

[20/45] 2026-08-05 07:03:15 | Comment | SAP Resolve
New attachment(s) added. Use the link(s) below to access on SAP Resolve portal

Error.png

----------------------------------------

[21/45] 2026-08-05 07:03:15 | Comment | SAP Resolve
Customer added a memo
at: 2026-08-05 05:00:54 GMT
Attachment uploaded

----------------------------------------

[22/45] 2026-08-05 07:01:16 | Comment | SAP Resolve
Customer added a memo
at: 2026-08-05 04:59:10 GMT

Hi Team, still we are getting error for parallel block creation

please find attached error screen shot

----------------------------------------

[23/45] 2026-08-05 07:01:16 | Field changes | SAP Resolve


----------------------------------------

[24/45] 2026-07-31 12:15:15 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-07-31 10:15:13 GMT
from:
There was a change in the case

----------------------------------------

[25/45] 2026-07-31 12:14:34 | Comment | Stefan Bartl
Send to Customer, updates that transfer case ownership to the customer


Thank you for providing the SupportInfo file.

Based on the error message ("Could not create the Parallel Block because each Parallel Block needs to contain at least two items" / "Execution list should contain 2 lists"), this behavior occurs when Tosca Commander cannot validate at least two independent items/lists in the current selection context.

To successfully create a Parallel Block, please ensure the following:

1. Open your ExecutionList structure in Tosca Commander.
2. Make sure you have at least two ExecutionEntries or ExecutionLists located on the same level (e.g., within the same folder).
3. Select both items simultaneously (using CTRL + Left Click).
4. Right-click the highlighted selection and choose "Create Parallel Block".

For further details on execution structures and parallel execution setups, you can refer to the following topics in our official product manual.

I suggest the following chapters from the manual could be interesting for you:
- Set up test execution with Tosca Distributed Execution
- Create and execute TestEvents
- Run Data Integrity tests in parallel
- Prepare and run parallel execution

If the issue persists after following these steps, could you please provide us with:
1. A step-by-step screenshot showing how you are selecting the items in Tosca Commander prior to right-clicking.
2. A full-window screenshot of the structure (showing where the test cases/entries are located).

Looking forward to your update!

Best Regards,

Stefan Bartl
Support Specialists
SAP Partner - Tricentis

----------------------------------------

[26/45] 2026-07-31 12:14:34 | Field changes | Stefan Bartl


----------------------------------------

[27/45] 2026-07-31 11:22:53 | Work notes | Henrique Anunciacao
Hi Stefan,

Analysis looks good.

I would ignore the call requests and not mention anything about it as it might irritate them at this state.

First step here is to investigate what they sent: Text + Attachments
Second is to do our own research and understand if we have everything we need to understand the issue: JIRA, Confluence, Manual, Past cases, Subtasks and KBs
Take note of any additional question you may need to ask them in order to guarantee they have done their setup as stated in official docs
Ask them any additional confirmation of the setup done: What have they done? Screenshots of the configurations, etc..?

I've noticed you have links to confluence pages there, which is fine for your own research, but try to push them to our product manual as much as you can.

--> I do think the error message here is clear enough, and all they have to do is to have two lists as mentioned in the message - unless there is something else at play, here.
--> If they insist in a remote call, then we can start dropping the support process line and explain that a call is the last resort, once all the needed info to investigate is provided.

----------------------------------------

[28/45] 2026-07-31 10:44:10 | Work notes | Stefan Bartl
Initial Analysis:
* Reviewed the reported errors ("Execution list should contain 2 lists" / "Could not create the Parallel Block because each Parallel Block needs to contain at least two items").
* Based on Tosca Commander object validation logic, this error occurs when the selected items are not recognized as two independent ExecutionEntries within the same container level.
* Verified environment details from the uploaded SupportInfo (Tosca 2024.2 / TC Components 24.2.3.0).

Recommendation:
1. Instead of scheduling a call right away, propose a quick troubleshooting step to the customer first (ensuring multi-selection of two ExecutionEntries within the same folder using CTRL+click)
2. Keep the meeting option open as a fallback if the step does not resolve the issue.

References:
- Confluence - Parallel Execution
- Confluence - DI Parallel Blocks

----------------------------------------

[29/45] 2026-07-29 08:43:22 | Comment | SAP Resolve
Customer added a memo
at: 2026-07-29 06:41:36 GMT
Attachment uploaded

----------------------------------------

[30/45] 2026-07-29 08:43:22 | Comment | SAP Resolve
New attachment(s) added. Use the link(s) below to access on SAP Resolve portal

ToscaSupportInfo.txt

----------------------------------------

[31/45] 2026-07-27 06:37:22 | Comment | SAP Resolve
Customer added a memo
at: 2026-07-27 04:35:48 GMT

Please schedule a meeting so we can investigate this issue together. This is not an intermittent problem and requires a dedicated working session to identify the root cause.

Thank you, and I look forward to resolving this issue together.

----------------------------------------

[32/45] 2026-07-27 06:37:22 | Field changes | SAP Resolve


----------------------------------------

[33/45] 2026-07-22 16:56:17 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-07-22 14:56:17 GMT
from:
There was a change in the case

----------------------------------------

[34/45] 2026-07-22 16:55:23 | Comment | Stefan Bartl
Send to Customer, updates that transfer case ownership to the customer


Thank you for reaching out to Tricentis Support via SAP. My name is Stefan, and I am the Technical Support Specialist assigned to your case.

To help us investigate this issue thoroughly and verify your exact patch level on Tosca 2024.2, could you please provide us with the SupportInfo file from your Tosca Commander instance?

1. In Tosca Commander go to Project - About Tosca - Support Info
2. Click on Support Info and save/export the resulting file.
3. Attach the generated file to this case.

Looking forward to hearing from you!

Best Regards,

Stefan Bartl
Support Specialists
SAP Partner - Tricentis

----------------------------------------

[35/45] 2026-07-22 16:55:23 | Field changes | Stefan Bartl


----------------------------------------

[36/45] 2026-07-22 16:21:43 | Work notes | Henrique Anunciacao
- issue a first response
- ask for the supportinfo file (we need to know her exact patch on 24.2)
- review documentation about parallel blocks
- review manual for any patch containing works around the subject

----------------------------------------

[37/45] 2026-07-22 16:21:42 | Work notes | Henrique Anunciacao
- issue a first response
- ask for the supportinfo file (we need to know her exact patch on 24.2)
- review documentation about parallel blocks
- review manual for any patch containing works around the subject

----------------------------------------

[38/45] 2026-07-22 16:20:24 | Field changes | Stefan Bartl


----------------------------------------

[39/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
Customer added a memo
at: 2026-07-21 07:04:46 GMT

Tosca version 2024.2, contact number 9966448133, Time zone: 8.30AM to 6PM IST. Please schedule meeting so that i can explain the issue in detail. attached the error screen hot for reference

----------------------------------------

[40/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
SAP added a memo for the partner
at: 2026-07-21 14:23:03 GMT
from: SAP

Dear Partner,

Here is a short summary of customer's issue and next action:

##Categorize the Case##

--Symptom--

- An error occurs when attempting to create a parallel block in Tosca.
- Error message: "Execution list should contain 2 lists."
- The system does not allow adding a block despite having two test cases in the execution list.

--Environment--

SAP ECT 2024.2

--Steps to reproduce--

1. Login to Tosca.
2. Add two test cases to the execution list.
3. In the order process, right-click and select the "Create parallel block" option.
4. An error message appears, preventing the creation of the parallel block.

--Business impact--

Moderately affected: Business operations are affected due to dysfunctional process.
Is there a workaround: No
It is affecting the ability to run concurrent user tests in the same Tosca instance, thereby hindering the delivery of project requirements.
Escalation Status: None

--Case contacts--


##Investigate & Diagnose##

--Data collected--

Customer information requested:
- On 13/07/2026 07:26:48, processor requested the customer to provide used technologies and versions, product version including patch level, relevant logs, and best contact number and working time zone.

Customer information received:
- On 21/07/2026 08:04:46, customer provided the information that Tosca version 2024.2, contact number 9966448133, Time zone: 8.30AM to 6PM IST.
- On 21/07/2026 08:06:06, customer provided the attachment "Parallel block error.png".

Tosca version 2024.2, contact number 9966448133, Time zone: 8.30AM to 6PM IST. Please schedule meeting so that i can explain the issue in detail. attached the error screen hot for reference

Error:
Could not create the Parallel Block because each Parallel Block needs to contain at least two items

--Research--

3193320 - How to collect different logs in Tosca
SupportInfo

Could not create the Parallel Block because each Parallel Block needs to contain at least two items

Nothing found on Tricentis SUpport Hub

Next Action

Please help the Customer with above issue/ query.

Many Thanks,
Regards,
SAP Global Partner Support

----------------------------------------

[41/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
New attachment(s) added. Use the link(s) below to access on SAP Resolve portal

Parallel block error.png

----------------------------------------

[42/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
SAP adds memo for the customer, not visible to the customer
at: 2026-07-13 06:26:48 GMT
from: SAP


Thank you for contacting SAP Global Partner Support.

I have a few clarifying questions that should help in providing a timely resolution:

Used technologies + versions (also including the environment, if relevant, e.g. OS)
Product version incl. patch level
Provide me the relevant logs too. Please check the following KBA for different logging options:
3193320 - How to collect different logs in Tosca
Best contact number, Email ID to reach you and your working time zone.

SupportInfo: https://support-hub.tricentis.com/open?id=kb_article_view&sys_kb_id=3dd298156fbc2540e2d616ff8d3ee4c8

With best regards,



----------------------------------------

[43/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
Customer added a memo
at: 2026-07-21 07:06:08 GMT

----------------------------------------

[44/45] 2026-07-21 16:25:16 | Comment | SAP Resolve
SAP adds memo for the customer, not visible to the customer
at: 2026-07-21 14:23:04 GMT
from: SAP

Thanks for providing the information.

Next Action

Please be advised that after my analysis, I have determined that further assistance from the partner is necessary. Therefore, I am forwarding your case to our partner for processing without any further delay.

Many Thanks,
Regards,


----------------------------------------

[45/45] 2026-07-21 16:25:16 | Field changes | SAP Resolve
