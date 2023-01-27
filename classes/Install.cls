// Copyright 2013, Daron Kallan - Sales Engineering, Salesforce.com Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// - Neither the name of the salesforce.com nor the names of its contributors
//   may be used to endorse or promote products derived from this software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



global class Install implements InstallHandler
{

	global void onInstall(InstallContext context)
	{

		if (context != null && context.isUpgrade())
		{
			if (context.previousVersion().compareTo(new Version(1,28)) < 0)
			{
				//  migrate old record ID to new record ID field
				try
				{
					List<EIT__c> oldEITs = [SELECT Id, RecordTypes__c FROM EIT__c WHERE RecordTypes__c != '' AND RecordTypes__c != NULL];
					if (oldEITs != null)
					{
						for (EIT__c eit : oldEITs)
						{
							eit.RecordTypes2__c = eit.RecordTypes__c;
							eit.RecordTypes__c = null;
						}
						update oldEITs;
					}
				}
				catch (Exception e)
				{
					
				}
			}
		}
		else if (context == null || (!context.isUpgrade() && !context.isPush()))
		{

			//
			//  set up default global custom settings
			//
			if (Timeline_Display__c.SObjectType.getDescribe().isCreateable())
			{
				Timeline_Display__c settings = new Timeline_Display__c();
				settings.Scrolling__c = false;
				settings.Zoom_Center__c = false;
				settings.Auto_Center_Recent__c = false;
				settings.Default_Zoom__c = 7;
				settings.Target__c = 'subtab';
				upsert settings;
			}

			Boolean eitOwner = false;
			Boolean catOwner = false;
			Id OwnerId = UserInfo.getUserId();
			if (context != null && context.installerId() != null) OwnerId = context.installerId();

			Schema.SObjectField ownerField = Schema.sObjectType.EIT__c.fields.getMap().get('OwnerId');
			if (ownerField != null) eitOwner = ownerField.getDescribe().isCreateable();
			ownerField = Schema.sObjectType.Category__c.fields.getMap().get('OwnerId');
			if (ownerField != null) catOwner = ownerField.getDescribe().isCreateable();


			//
			//  create default trackers
			//

			List<EIT__c> eits  =  new List<EIT__c>();


			//
			//  create Customer (Account/Contact) trackers
			//

			Category__c accat1 = new Category__c();
			accat1.Name = 'Activities';
			accat1.DefaultVisibility__c = true;
			if (catOwner) accat1.put('OwnerId', OwnerId);

			Category__c accat2 = new Category__c();
			accat2.Name = 'Cases';
			accat2.DefaultVisibility__c = true;
			if (catOwner) accat2.put('OwnerId', OwnerId);

			Category__c accat3 = new Category__c();
			accat3.Name = 'Product Expiry';
			accat3.DefaultVisibility__c = false;
			if (catOwner) accat3.put('OwnerId', OwnerId);

			Category__c accat4 = new Category__c();
			accat4.Name = 'Cases - All';
			accat4.DefaultVisibility__c = false;
			if (catOwner) accat4.put('OwnerId', OwnerId);

			Category__c accat5 = new Category__c();
			accat5.Name = 'Sales';
			accat5.DefaultVisibility__c = true;
			if (catOwner) accat5.put('OwnerId', OwnerId);

			Category__c accat6 = new Category__c();
			accat6.Name = 'Marketing';
			accat6.DefaultVisibility__c = true;
			if (catOwner) accat6.put('OwnerId', OwnerId);

			if (Category__c.SObjectType.getDescribe().isCreateable())
			{
				insert accat1;
				insert accat2;
				insert accat3;
				insert accat4;
				insert accat5;
				insert accat6;
			}

			EIT__c eit1 = new EIT__c();
			eit1.Name = 'Cases';
			eit1.AccountContactMatching__c = 'ORC';
			eit1.Category__c = accat2.Id;
			eit1.DescriptionField__c = 'Description';
			eit1.EndTimeValue__c = 'ClosedDate';
			eit1.ExecuteAsSubquery__c = false;
			eit1.HoverField__c = 'CaseNumber';
			eit1.ObjectType__c = 'Case';
			eit1.Order__c = 1;
			eit1.ParentAccountIDField__c = 'AccountId';
			eit1.ParentContactIDField__c = 'ContactId';
			eit1.RecordIDField__c = 'Id';
			eit1.RecordLimit__c = 50;
			eit1.RecordNameField__c = 'Subject';
			eit1.StartTimeValue__c = 'CreatedDate';
			eit1.Color__c = 'white';
			eit1.TextColor__c = 'black';
			eit1.Icon__c = '/resource/slt__Resources/SFDC_case_icon.png';
			eit1.Image__c = '/resource/slt__Resources/SFDC_case_image.png';
			eit1.TapeImage__c = '/resource/slt__Resources/tape_blue_chevrons.png';
			eit1.TapeRepeat__c = 'repeat';
			eit1.Description__c = 'Example of a basic Case tracker';
			if (eitOwner) eit1.put('OwnerId', OwnerId);
			eits.add(eit1);

			EIT__c eit2 = new EIT__c();
			eit2.Name = 'All Cases';
			eit2.AccountContactMatching__c = 'CTX';
			eit2.Category__c = accat4.Id;
			eit2.DescriptionField__c = 'Description';
			eit2.EndTimeValue__c = 'ClosedDate';
			eit2.ExecuteAsSubquery__c = false;
			eit2.HoverField__c = 'CaseNumber';
			eit2.ObjectType__c = 'Case';
			eit2.Order__c = 2;
			eit2.ParentAccountIDField__c = 'AccountId';
			eit2.ParentContactIDField__c = 'ContactId';
			eit2.RecordIDField__c = 'Id';
			eit2.RecordLimit__c = 50;
			eit2.RecordNameField__c = 'Subject';
			eit2.StartTimeValue__c = 'CreatedDate';
			eit2.Color__c = 'gray';
			eit2.TextColor__c = 'darkgray';
			eit2.Icon__c = '/resource/slt__Resources/SFDC_case_icon.png';
			eit2.Image__c = '/resource/slt__Resources/SFDC_case_image.png';
			eit2.TapeImage__c = '/resource/slt__Resources/tape_blue_wave.png';
			eit2.TapeRepeat__c = 'repeat';
			eit2.Description__c = 'Example of a Case Tracker that shows all cases for a given People First context (note the Account/Contact Matching logic)';
			if (eitOwner) eit2.put('OwnerId', OwnerId);
			eits.add(eit2);

			EIT__c eit3 = new EIT__c();
			eit3.Name = 'Email (Opened)';
			eit3.AccountContactMatching__c = 'CTX';
			eit3.Category__c = accat1.Id;
			eit3.DescriptionFieldPath__c = 'TaskId.';
			eit3.DescriptionField__c = 'Task.Description';
			eit3.EndTimeValue__c = 'FirstOpenDate';
			eit3.ExecuteAsSubquery__c = true;
			eit3.HoverField__c = 'EmailTemplateName';
			eit3.InclusionField__c = 'FirstOpenDate';
			eit3.ObjectType__c = 'EmailStatus';
			eit3.Order__c = 3;
			eit3.ParentContactIDField__c = 'EmailStatuses';
			eit3.RecordIDField__c = 'TaskId';
			eit3.RecordLimit__c = 50;
			eit3.RecordNameFieldPath__c = 'TaskId.';
			eit3.RecordNameField__c = 'Task.Subject';
			eit3.StartTimeValuePath__c = 'TaskId.';
			eit3.StartTimeValue__c = 'Task.ActivityDate';
			eit3.TextColor__c = 'green';
			eit3.Icon__c = '/resource/slt__Resources/SFDC_mail_icon.png';
			eit3.Image__c = '/resource/slt__Resources/SFDC_mail_image.png';
			eit3.TapeImage__c = '/resource/slt__Resources/tape_green_light_stripes.png';
			eit3.TapeRepeat__c = 'repeat';
			eit3.Description__c = 'Example of an opened email activity tracker for HTML emails. Uses an inclusion field of FirstOpenDate. Uses the associated task activity date and activity Id to override Activity History.';
			if (eitOwner) eit3.put('OwnerId', OwnerId);
			eits.add(eit3);

			EIT__c eit4 = new EIT__c();
			eit4.Name = 'Email';
			eit4.AccountContactMatching__c = 'CTX';
			eit4.Category__c = accat1.Id;
			eit4.DescriptionFieldPath__c = 'TaskId.';
			eit4.DescriptionField__c = 'Task.Description';
			eit4.ExecuteAsSubquery__c = true;
			eit4.HoverField__c = 'EmailTemplateName';
			eit4.ObjectType__c = 'EmailStatus';
			eit4.Order__c = 4;
			eit4.ParentContactIDField__c = 'EmailStatuses';
			eit4.RecordIDField__c = 'TaskId';
			eit4.RecordLimit__c = 50;
			eit4.RecordNameFieldPath__c = 'TaskId.';
			eit4.RecordNameField__c = 'Task.Subject';
			eit4.StartTimeValuePath__c = 'TaskId.';
			eit4.StartTimeValue__c = 'Task.ActivityDate';
			eit4.Icon__c = '/resource/slt__Resources/SFDC_mail_icon.png';
			eit4.Image__c = '/resource/slt__Resources/SFDC_mail_image.png';
			eit4.Description__c = 'Example of an email activity tracker. Uses the associated task activity date and activity Id to override Activity History.';
			if (eitOwner) eit4.put('OwnerId', OwnerId);
			eits.add(eit4);

			EIT__c eit5 = new EIT__c();
			eit5.Name = 'Activity History';
			eit5.AccountContactMatching__c = 'CTX';
			eit5.Category__c = accat1.Id;
			eit5.DescriptionField__c = 'Description';
			eit5.EndTimeValue__c = 'EndDateTime';
			eit5.ExecuteAsSubquery__c = true;
			eit5.HoverField__c = 'Status';
			eit5.ObjectType__c = 'ActivityHistory';
			eit5.Order__c = 5;
			eit5.ParentAccountIDField__c = 'ActivityHistories';
			eit5.ParentContactIDField__c = 'ActivityHistories';
			eit5.RecordIDField__c = 'Id';
			eit5.RecordLimit__c = 50;
			eit5.RecordNameField__c = 'Subject';
			eit5.StartTimeValue__c = 'ActivityDate';
			eit5.Color__c = '#909090';
			eit5.TextColor__c = 'black';
			eit5.Icon__c = '/resource/slt__Resources/phone_icon.png';
			eit5.Image__c = '/resource/slt__Resources/phone_image.png';
			eit5.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit5.TapeRepeat__c = 'repeat';
			eit5.Description__c = 'Example of an Activity History tracker';
			if (eitOwner) eit5.put('OwnerId', OwnerId);
			eits.add(eit5);

			EIT__c eit6 = new EIT__c();
			eit6.Name = 'Open Activities';
			eit6.AccountContactMatching__c = 'CTX';
			eit6.Category__c = accat1.Id;
			eit6.DescriptionField__c = 'Description';
			eit6.EndTimeValue__c = 'EndDateTime';
			eit6.ExecuteAsSubquery__c = true;
			eit6.HoverField__c = 'Status';
			eit6.ObjectType__c = 'OpenActivity';
			eit6.Order__c = 6;
			eit6.ParentAccountIDField__c = 'OpenActivities';
			eit6.ParentContactIDField__c = 'OpenActivities';
			eit6.RecordIDField__c = 'Id';
			eit6.RecordLimit__c = 50;
			eit6.RecordNameField__c = 'Subject';
			eit6.StartTimeValue__c = 'ActivityDate';
			eit6.Color__c = 'yellow';
			eit6.TextColor__c = 'black';
			eit6.Icon__c = '/resource/slt__Resources/clock_icon.png';
			eit6.Image__c = '/resource/slt__Resources/clock_image.png';
			eit6.TapeImage__c = '/resource/slt__Resources/tape_red_stripes.png';
			eit6.TapeRepeat__c = 'repeat';
			eit6.Description__c = 'Example of an Open Activity tracker';
			if (eitOwner) eit6.put('OwnerId', OwnerId);
			eits.add(eit6);

			EIT__c eit7 = new EIT__c();
			eit7.Name = 'Attachments';
			eit7.AccountContactMatching__c = 'CTX';
			eit7.Category__c = accat1.Id;
			eit7.DescriptionField__c = 'Description';
			eit7.ExecuteAsSubquery__c = false;
			eit7.HoverField__c = 'ContentType';
			eit7.ObjectType__c = 'Attachment';
			eit7.Order__c = 7;
			eit7.ParentAccountIDField__c = 'ParentId';
			eit7.ParentContactIDField__c = 'ParentId';
			eit7.RecordIDField__c = 'Id';
			eit7.RecordLimit__c = 50;
			eit7.RecordNameField__c = 'Name';
			eit7.StartTimeValue__c = 'LastModifiedDate';
			eit7.Icon__c = '/resource/slt__Resources/SFDC_box_icon.png';
			eit7.Image__c = '/resource/slt__Resources/SFDC_box_image.png';
			eit7.Description__c = 'Example of an Attachment tracker';
			if (eitOwner) eit7.put('OwnerId', OwnerId);
			eits.add(eit7);

			EIT__c eit8 = new EIT__c();
			eit8.Name = 'Asset Expiration';
			eit8.AccountContactMatching__c = 'CTX';
			eit8.Category__c = accat3.Id;
			eit8.DescriptionField__c = 'Description';
			eit8.ExecuteAsSubquery__c = false;
			eit8.HoverFieldPath__c = 'Product2Id.';
			eit8.HoverField__c = 'Product2.Family';
			eit8.ObjectType__c = 'Asset';
			eit8.Order__c = 8;
			eit8.ParentAccountIDField__c = 'AccountId';
			eit8.ParentContactIDField__c = 'ContactId';
			eit8.RecordIDField__c = 'Id';
			eit8.RecordLimit__c = 50;
			eit8.RecordNameField__c = 'Name';
			eit8.StartTimeValue__c = 'UsageEndDate';
			eit8.TextColor__c = 'red';
			eit8.Icon__c = '/resource/slt__Resources/SFDC_buildingBlock_icon.png';
			eit8.Image__c = '/resource/slt__Resources/SFDC_buildingBlock_image.png';
			eit8.Description__c = 'Example of an Asset expiration tracker - especially useful for subscriptions';
			if (eitOwner) eit8.put('OwnerId', OwnerId);
			eits.add(eit8);

			EIT__c eit9 = new EIT__c();
			eit9.Name = 'Won Opportunities';
			eit9.AccountContactMatching__c = 'CTX';
			eit9.Category__c = accat5.Id;
			eit9.DescriptionField__c = 'Description';
			eit9.ExecuteAsSubquery__c = false;
			eit9.HoverField__c = 'Amount';
			eit9.InclusionField__c = 'IsWon';
			eit9.ObjectType__c = 'Opportunity';
			eit9.Order__c = 9;
			eit9.ParentAccountIDField__c = 'AccountId';
			eit9.RecordIDField__c = 'Id';
			eit9.RecordLimit__c = 50;
			eit9.RecordNameField__c = 'Name';
			eit9.StartTimeValue__c = 'CloseDate';
			eit9.Icon__c = '/resource/slt__Resources/money_icon.png';
			eit9.Image__c = '/resource/slt__Resources/money_image.png';
			eit9.Description__c = 'Example of a Closed/Won Opportunity tracker - uses "Is Won" as the Inclusion Field to override subsequent trackers.';
			if (eitOwner) eit9.put('OwnerId', OwnerId);
			eits.add(eit9);

			EIT__c eit10 = new EIT__c();
			eit10.Name = 'Won Opportunities (Contact)';
			eit10.AccountContactMatching__c = 'ORC';
			eit10.Category__c = accat5.Id;
			eit10.DescriptionFieldPath__c = 'OpportunityId.';
			eit10.DescriptionField__c = 'Opportunity.Description';
			eit10.ExecuteAsSubquery__c = false;
			eit10.HoverFieldPath__c = 'OpportunityId.';
			eit10.HoverField__c = 'Opportunity.Amount';
			eit10.InclusionFieldPath__c = 'OpportunityId.';
			eit10.InclusionField__c = 'Opportunity.IsWon';
			eit10.ObjectType__c = 'OpportunityContactRole';
			eit10.Order__c = 10;
			eit10.ParentContactIDField__c = 'ContactId';
			eit10.ParentAccountIDField__c = 'Opportunity.AccountId';
			eit10.ParentAccountIDFieldPath__c = 'OpportunityId.';
			eit10.RecordIDField__c = 'OpportunityId';
			eit10.RecordLimit__c = 50;
			eit10.RecordNameFieldPath__c = 'OpportunityId.';
			eit10.RecordNameField__c = 'Opportunity.Name';
			eit10.StartTimeValuePath__c = 'OpportunityId.';
			eit10.StartTimeValue__c = 'Opportunity.CloseDate';
			eit10.Icon__c = '/resource/slt__Resources/money_icon.png';
			eit10.Image__c = '/resource/slt__Resources/money_image.png';
			eit10.Description__c = 'Example of a Closed/Won Opportunity tracker for Opportunity Contact Roles - uses "Is Won" as the Inclusion Field and a parent record ID';
			if (eitOwner) eit10.put('OwnerId', OwnerId);
			eits.add(eit10);

			EIT__c eit11 = new EIT__c();
			eit11.Name = 'Lost Opportunities';
			eit11.AccountContactMatching__c = 'CTX';
			eit11.Category__c = accat5.Id;
			eit11.DescriptionField__c = 'Description';
			eit11.ExecuteAsSubquery__c = false;
			eit11.HoverField__c = 'Amount';
			eit11.InclusionField__c = 'IsClosed';
			eit11.ObjectType__c = 'Opportunity';
			eit11.Order__c = 11;
			eit11.ParentAccountIDField__c = 'AccountId';
			eit11.RecordIDField__c = 'Id';
			eit11.RecordLimit__c = 50;
			eit11.RecordNameField__c = 'Name';
			eit11.StartTimeValue__c = 'CloseDate';
			eit11.Icon__c = '/resource/slt__Resources/smiley_unhappy_icon.png';
			eit11.Image__c = '/resource/slt__Resources/smiley_unhappy_image.png';
			eit11.Description__c = 'Example of a Closed/Lost Opportunity tracker - uses "Is Closed" as the Inclusion Field';
			if (eitOwner) eit11.put('OwnerId', OwnerId);
			eits.add(eit11);

			EIT__c eit12 = new EIT__c();
			eit12.Name = 'Lost Opportunities (Contact)';
			eit12.AccountContactMatching__c = 'ORC';
			eit12.Category__c = accat5.Id;
			eit12.DescriptionFieldPath__c = 'OpportunityId.';
			eit12.DescriptionField__c = 'Opportunity.Description';
			eit12.ExecuteAsSubquery__c = false;
			eit12.HoverFieldPath__c = 'OpportunityId.';
			eit12.HoverField__c = 'Opportunity.Amount';
			eit12.InclusionFieldPath__c = 'OpportunityId.';
			eit12.InclusionField__c = 'Opportunity.IsClosed';
			eit12.ObjectType__c = 'OpportunityContactRole';
			eit12.Order__c = 12;
			eit12.ParentContactIDField__c = 'ContactId';
			eit12.ParentAccountIDField__c = 'Opportunity.AccountId';
			eit12.ParentAccountIDFieldPath__c = 'OpportunityId.';
			eit12.RecordIDField__c = 'OpportunityId';
			eit12.RecordLimit__c = 50;
			eit12.RecordNameFieldPath__c = 'OpportunityId.';
			eit12.RecordNameField__c = 'Opportunity.Name';
			eit12.StartTimeValuePath__c = 'OpportunityId.';
			eit12.StartTimeValue__c = 'Opportunity.CloseDate';
			eit12.Icon__c = '/resource/slt__Resources/smiley_unhappy_icon.png';
			eit12.Image__c = '/resource/slt__Resources/smiley_unhappy_image.png';
			eit12.Description__c = 'Example of a Closed/Lost Opportunity tracker for Opportunity Contact Roles - uses "Is Closed" as the Inclusion Field and a parent record ID';
			if (eitOwner) eit12.put('OwnerId', OwnerId);
			eits.add(eit12);

			EIT__c eit13 = new EIT__c();
			eit13.Name = 'Open Opportunities';
			eit13.AccountContactMatching__c = 'CTX';
			eit13.Category__c = accat5.Id;
			eit13.DescriptionField__c = 'Description';
			eit13.ExecuteAsSubquery__c = false;
			eit13.HoverField__c = 'Amount';
			eit13.InclusionField__c = 'Probability';
			eit13.ObjectType__c = 'Opportunity';
			eit13.Order__c = 13;
			eit13.ParentAccountIDField__c = 'AccountId';
			eit13.RecordIDField__c = 'Id';
			eit13.RecordLimit__c = 50;
			eit13.RecordNameField__c = 'Name';
			eit13.StartTimeValue__c = 'CloseDate';
			eit13.Icon__c = '/resource/slt__Resources/SFDC_opportunity_icon.png';
			eit13.Image__c = '/resource/slt__Resources/SFDC_opportunity_image.png';
			eit13.Description__c = 'Example of an Open Opportunity tracker - uses "Probability" as the Inclusion Field';
			if (eitOwner) eit13.put('OwnerId', OwnerId);
			eits.add(eit13);

			EIT__c eit14 = new EIT__c();
			eit14.Name = 'Open Opportunities (Contact)';
			eit14.AccountContactMatching__c = 'ORC';
			eit14.Category__c = accat5.Id;
			eit14.DescriptionFieldPath__c = 'OpportunityId.';
			eit14.DescriptionField__c = 'Opportunity.Description';
			eit14.ExecuteAsSubquery__c = false;
			eit14.HoverFieldPath__c = 'OpportunityId.';
			eit14.HoverField__c = 'Opportunity.Amount';
			eit14.InclusionFieldPath__c = 'OpportunityId.';
			eit14.InclusionField__c = 'Opportunity.Probability';
			eit14.ObjectType__c = 'OpportunityContactRole';
			eit14.Order__c = 14;
			eit14.ParentContactIDField__c = 'ContactId';
			eit14.ParentAccountIDField__c = 'Opportunity.AccountId';
			eit14.ParentAccountIDFieldPath__c = 'OpportunityId.';
			eit14.RecordIDField__c = 'OpportunityId';
			eit14.RecordLimit__c = 50;
			eit14.RecordNameFieldPath__c = 'OpportunityId.';
			eit14.RecordNameField__c = 'Opportunity.Name';
			eit14.StartTimeValuePath__c = 'OpportunityId.';
			eit14.StartTimeValue__c = 'Opportunity.CloseDate';
			eit14.Icon__c = '/resource/slt__Resources/SFDC_opportunity_icon.png';
			eit14.Image__c = '/resource/slt__Resources/SFDC_opportunity_image.png';
			eit14.Description__c = 'Example of an Open Opportunity tracker for Opportunity Contact Roles - uses "Probability" as the Inclusion Field and a parent record ID';
			if (eitOwner) eit14.put('OwnerId', OwnerId);
			eits.add(eit14);

			EIT__c eit15 = new EIT__c();
			eit15.Name = 'Campaign History (Responded)';
			eit15.AccountContactMatching__c = 'CTX';
			eit15.Category__c = accat6.Id;
			eit15.DescriptionFieldPath__c = 'CampaignId.';
			eit15.DescriptionField__c = 'Campaign.Description';
			eit15.EndTimeValue__c = 'FirstRespondedDate';
			eit15.ExecuteAsSubquery__c = false;
			eit15.HoverField__c = 'Status';
			eit15.InclusionField__c = 'HasResponded';
			eit15.ObjectType__c = 'CampaignMember';
			eit15.Order__c = 15;
			eit15.ParentContactIDField__c = 'ContactId';
			eit15.RecordIDField__c = 'Id';
			eit15.RecordLimit__c = 50;
			eit15.RecordNameFieldPath__c = 'CampaignId.';
			eit15.RecordNameField__c = 'Campaign.Name';
			eit15.StartTimeValue__c = 'CreatedDate';
			eit15.TextColor__c = 'green';
			eit15.Icon__c = '/resource/slt__Resources/smiley_happy_icon.png';
			eit15.Image__c = '/resource/slt__Resources/smiley_happy_image.png';
			eit15.TapeImage__c = '/resource/slt__Resources/tape_green_stripes.png';
			eit15.TapeRepeat__c = 'repeat';
			eit15.Description__c = 'Example of a Campaign History tracker for Contacts - those without a First Responded Date get captured by the following tracker';
			if (eitOwner) eit15.put('OwnerId', OwnerId);
			eits.add(eit15);

			EIT__c eit16 = new EIT__c();
			eit16.Name = 'Campaign History (No Response)';
			eit16.AccountContactMatching__c = 'CTX';
			eit16.Category__c = accat6.Id;
			eit16.DescriptionFieldPath__c = 'CampaignId.';
			eit16.DescriptionField__c = 'Campaign.Description';
			eit16.ExecuteAsSubquery__c = false;
			eit16.HoverField__c = 'Status';
			eit16.ObjectType__c = 'CampaignMember';
			eit16.Order__c = 16;
			eit16.ParentContactIDField__c = 'ContactId';
			eit16.RecordIDField__c = 'Id';
			eit16.RecordLimit__c = 50;
			eit16.RecordNameFieldPath__c = 'CampaignId.';
			eit16.RecordNameField__c = 'Campaign.Name';
			eit16.StartTimeValue__c = 'CreatedDate';
			eit16.Icon__c = '/resource/slt__Resources/SFDC_star_icon.png';
			eit16.Image__c = '/resource/slt__Resources/SFDC_star_image.png';
			eit16.Description__c = 'Example of a Campaign History tracker for Contacts - those with a First Responded Date get captured by the previous tracker';
			if (eitOwner) eit16.put('OwnerId', OwnerId);
			eits.add(eit16);


			//
			//  create Case trackers
			//

			Category__c ccat1 = new Category__c();
			ccat1.Name = 'Activities';
			ccat1.CustomTimelineObject__c = 'Case';
			ccat1.DefaultVisibility__c = true;
			if (catOwner) ccat1.put('OwnerId', OwnerId);

			Category__c ccat2 = new Category__c();
			ccat2.Name = 'Subcases';
			ccat2.CustomTimelineObject__c = 'Case';
			ccat2.DefaultVisibility__c = false;
			if (catOwner) ccat2.put('OwnerId', OwnerId);

			if (Category__c.SObjectType.getDescribe().isCreateable())
			{
				insert ccat1;
				insert ccat2;
			}

			EIT__c eit17 = new EIT__c();
			eit17.Name = 'Activity History';
			eit17.Category__c = ccat1.Id;
			eit17.CustomTimelineObject__c = 'Case';
			eit17.DescriptionField__c = 'Description';
			eit17.EndTimeValue__c = 'EndDateTime';
			eit17.ExecuteAsSubquery__c = true;
			eit17.HoverField__c = 'Status';
			eit17.ObjectType__c = 'ActivityHistory';
			eit17.Order__c = 1;
			eit17.ParentAccountIDField__c = 'ActivityHistories';
			eit17.RecordIDField__c = 'Id';
			eit17.RecordLimit__c = 50;
			eit17.RecordNameField__c = 'Subject';
			eit17.StartTimeValue__c = 'ActivityDate';
			eit17.Icon__c = '/resource/slt__Resources/phone_icon.png';
			eit17.Image__c = '/resource/slt__Resources/phone_image.png';
			eit17.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit17.TapeRepeat__c = 'repeat';
			eit17.Description__c = 'Example of an Activity History tracker';
			if (eitOwner) eit17.put('OwnerId', OwnerId);
			eits.add(eit17);

			EIT__c eit18 = new EIT__c();
			eit18.Name = 'Open Activities';
			eit18.Category__c = ccat1.Id;
			eit18.CustomTimelineObject__c = 'Case';
			eit18.DescriptionField__c = 'Description';
			eit18.EndTimeValue__c = 'EndDateTime';
			eit18.ExecuteAsSubquery__c = true;
			eit18.HoverField__c = 'Status';
			eit18.ObjectType__c = 'OpenActivity';
			eit18.Order__c = 2;
			eit18.ParentAccountIDField__c = 'OpenActivities';
			eit18.RecordIDField__c = 'Id';
			eit18.RecordLimit__c = 50;
			eit18.RecordNameField__c = 'Subject';
			eit18.StartTimeValue__c = 'ActivityDate';
			eit18.Icon__c = '/resource/slt__Resources/clock_icon.png';
			eit18.Image__c = '/resource/slt__Resources/clock_image.png';
			eit18.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit18.TapeRepeat__c = 'repeat';
			eit18.Description__c = 'Example of an Open Activity tracker';
			if (eitOwner) eit18.put('OwnerId', OwnerId);
			eits.add(eit18);

			EIT__c eit19 = new EIT__c();
			eit19.Name = 'Case Comments';
			eit19.Category__c = ccat1.Id;
			eit19.CustomTimelineObject__c = 'Case';
			eit19.DescriptionField__c = 'CommentBody';
			eit19.ExecuteAsSubquery__c = false;
			eit19.HoverFieldPath__c = 'ParentId.';
			eit19.HoverField__c = 'Parent.CaseNumber';
			eit19.ObjectType__c = 'CaseComment';
			eit19.Order__c = 3;
			eit19.ParentAccountIDField__c = 'ParentId';
			eit19.RecordIDField__c = 'Id';
			eit19.RecordLimit__c = 50;
			eit19.RecordNameFieldPath__c = 'CreatedById.';
			eit19.RecordNameField__c = 'CreatedBy.Name';
			eit19.StartTimeValue__c = 'CreatedDate';
			eit19.Icon__c = '/resource/slt__Resources/SFDC_pencil_icon.png';
			eit19.Image__c = '/resource/slt__Resources/SFDC_pencil_image.png';
			eit19.Description__c = 'Example of a Case Comments tracker';
			if (eitOwner) eit19.put('OwnerId', OwnerId);
			eits.add(eit19);

			EIT__c eit20 = new EIT__c();
			eit20.Name = 'Case Solution';
			// eit20.Category__c = ccat1.Id;
			eit20.CustomTimelineObject__c = 'Case';
			eit20.DescriptionFieldPath__c = 'SolutionId.';
			eit20.DescriptionField__c = 'Solution.SolutionNote';
			eit20.ExecuteAsSubquery__c = false;
			eit20.HoverFieldPath__c = 'CaseId.';
			eit20.HoverField__c = 'Case.CaseNumber';
			eit20.ObjectType__c = 'CaseSolution';
			eit20.Order__c = 4;
			eit20.ParentAccountIDField__c = 'CaseId';
			eit20.RecordIDField__c = 'Id';
			eit20.RecordLimit__c = 50;
			eit20.RecordNameFieldPath__c = 'SolutionId.';
			eit20.RecordNameField__c = 'Solution.SolutionName';
			eit20.StartTimeValue__c = 'CreatedDate';
			eit20.Icon__c = '/resource/slt__Resources/SFDC_lightbulb_icon.png';
			eit20.Image__c = '/resource/slt__Resources/SFDC_lightbulb_image.png';
			eit20.Description__c = 'Example of a Case Solutions tracker';
			if (eitOwner) eit20.put('OwnerId', OwnerId);
			eits.add(eit20);

			EIT__c eit21 = new EIT__c();
			eit21.Name = 'Attachments';
			eit21.Category__c = ccat1.Id;
			eit21.CustomTimelineObject__c = 'Case';
			eit21.DescriptionField__c = 'Description';
			eit21.ExecuteAsSubquery__c = false;
			eit21.HoverField__c = 'ContentType';
			eit21.ObjectType__c = 'Attachment';
			eit21.Order__c = 5;
			eit21.ParentAccountIDField__c = 'ParentId';
			eit21.RecordIDField__c = 'Id';
			eit21.RecordLimit__c = 50;
			eit21.RecordNameField__c = 'Name';
			eit21.StartTimeValue__c = 'CreatedDate';
			eit21.Icon__c = '/resource/slt__Resources/SFDC_box_icon.png';
			eit21.Image__c = '/resource/slt__Resources/SFDC_box_image.png';
			eit21.Description__c = 'Example of an Attachments tracker';
			if (eitOwner) eit21.put('OwnerId', OwnerId);
			eits.add(eit21);

			EIT__c eit22 = new EIT__c();
			eit22.Name = 'Case Opened';
			// eit22.Category__c = ccat1.Id;
			eit22.CustomTimelineObject__c = 'Case';
			eit22.DescriptionField__c = 'Description';
			eit22.ExecuteAsSubquery__c = false;
			eit22.HoverField__c = 'Reason';
			eit22.ObjectType__c = 'Case';
			eit22.Order__c = 6;
			eit22.ParentAccountIDField__c = 'Id';
			eit22.RecordIDField__c = 'Id';
			eit22.RecordLimit__c = 50;
			eit22.RecordNameField__c = 'Subject';
			eit22.StartTimeValue__c = 'CreatedDate';
			eit22.Icon__c = '/resource/slt__Resources/SFDC_redcross_icon.png';
			eit22.Image__c = '/resource/slt__Resources/SFDC_case_image.png';
			eit22.Description__c = 'Example of a self-referential record start time';
			if (eitOwner) eit22.put('OwnerId', OwnerId);
			eits.add(eit22);

			EIT__c eit23 = new EIT__c();
			eit23.Name = 'Case Closed';
			// eit23.Category__c = ccat1.Id;
			eit23.CustomTimelineObject__c = 'Case';
			eit23.DescriptionField__c = 'Description';
			eit23.ExecuteAsSubquery__c = false;
			eit23.HoverFieldPath__c = 'OwnerId[User].';
			eit23.HoverField__c = 'Owner.Name';
			eit23.ObjectType__c = 'Case';
			eit23.Order__c = 7;
			eit23.ParentAccountIDField__c = 'Id';
			eit23.RecordIDField__c = 'Id';
			eit23.RecordLimit__c = 50;
			eit23.RecordNameField__c = 'Status';
			eit23.StartTimeValue__c = 'ClosedDate';
			eit23.Icon__c = '/resource/slt__Resources/greencheck_icon.png';
			eit23.Image__c = '/resource/slt__Resources/SFDC_case_image.png';
			eit23.Description__c = 'Example of a self-referential record close time. Although it uses the same ID, it does not conflict with Case Started because the time is different.';
			if (eitOwner) eit23.put('OwnerId', OwnerId);
			eits.add(eit23);

			EIT__c eit24 = new EIT__c();
			eit24.Name = 'Child Cases';
			eit24.Category__c = ccat2.Id;
			eit24.CustomTimelineObject__c = 'Case';
			eit24.DescriptionField__c = 'Description';
			eit24.EndTimeValue__c = 'ClosedDate';
			eit24.ExecuteAsSubquery__c = false;
			eit24.HoverField__c = 'CaseNumber';
			eit24.ObjectType__c = 'Case';
			eit24.Order__c = 8;
			eit24.ParentAccountIDField__c = 'ParentId';
			eit24.RecordIDField__c = 'Id';
			eit24.RecordLimit__c = 50;
			eit24.RecordNameField__c = 'Subject';
			eit24.StartTimeValue__c = 'CreatedDate';
			eit24.Icon__c = '/resource/slt__Resources/SFDC_case_icon.png';
			eit24.Image__c = '/resource/slt__Resources/SFDC_case_image.png';
			eit24.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit24.TapeRepeat__c = 'repeat';
			eit24.Description__c = 'Example of a child Case tracker.';
			if (eitOwner) eit24.put('OwnerId', OwnerId);
			eits.add(eit24);

			EIT__c eit25 = new EIT__c();
			eit25.Name = 'Child Case Comments';
			eit25.Category__c = ccat2.Id;
			eit25.CustomTimelineObject__c = 'Case';
			eit25.DescriptionField__c = 'CommentBody';
			eit25.ExecuteAsSubquery__c = false;
			eit25.HoverFieldPath__c = 'ParentId.';
			eit25.HoverField__c = 'Parent.CaseNumber';
			eit25.ObjectType__c = 'CaseComment';
			eit25.Order__c = 9;
			eit25.ParentAccountIDFieldPath__c = 'ParentId.';
			eit25.ParentAccountIDField__c = 'Parent.ParentId';
			eit25.RecordIDField__c = 'Id';
			eit25.RecordLimit__c = 50;
			eit25.RecordNameFieldPath__c = 'CreatedById.';
			eit25.RecordNameField__c = 'CreatedBy.Name';
			eit25.StartTimeValue__c = 'CreatedDate';
			eit25.Icon__c = '/resource/slt__Resources/SFDC_pencil_icon.png';
			eit25.Image__c = '/resource/slt__Resources/SFDC_pencil_image.png';
			eit25.Description__c = 'Example of a child Case related record tracker for Case Comments. Hover shows Case ID to differentiate related case.';
			if (eitOwner) eit25.put('OwnerId', OwnerId);
			eits.add(eit25);

			EIT__c eit26 = new EIT__c();
			eit26.Name = 'Child Case Solutions';
			eit26.Category__c = ccat2.Id;
			eit26.CustomTimelineObject__c = 'Case';
			eit26.DescriptionFieldPath__c = 'SolutionId.';
			eit26.DescriptionField__c = 'Solution.SolutionNote';
			eit26.ExecuteAsSubquery__c = false;
			eit26.HoverFieldPath__c = 'CaseId.';
			eit26.HoverField__c = 'Case.CaseNumber';
			eit26.ObjectType__c = 'CaseSolution';
			eit26.Order__c = 10;
			eit26.ParentAccountIDFieldPath__c = 'CaseId.';
			eit26.ParentAccountIDField__c = 'Case.ParentId';
			eit26.RecordIDField__c = 'Id';
			eit26.RecordLimit__c = 50;
			eit26.RecordNameFieldPath__c = 'SolutionId.';
			eit26.RecordNameField__c = 'Solution.SolutionName';
			eit26.StartTimeValue__c = 'CreatedDate';
			eit26.Icon__c = '/resource/slt__Resources/SFDC_lightbulb_icon.png';
			eit26.Image__c = '/resource/slt__Resources/SFDC_lightbulb_image.png';
			eit26.Description__c = 'Example of a child Case related record tracker for Case Solutions. Hover shows Case ID to differentiate related case.';
			if (eitOwner) eit26.put('OwnerId', OwnerId);
			eits.add(eit26);


			//
			//  create Lead trackers
			//

			Category__c lcat1 = new Category__c();
			lcat1.Name = 'Activities';
			lcat1.CustomTimelineObject__c = 'Lead';
			lcat1.DefaultVisibility__c = true;
			if (catOwner) lcat1.put('OwnerId', OwnerId);

			Category__c lcat2 = new Category__c();
			lcat2.Name = 'Marketing';
			lcat2.CustomTimelineObject__c = 'Lead';
			lcat2.DefaultVisibility__c = true;
			if (catOwner) lcat2.put('OwnerId', OwnerId);

			if (Category__c.SObjectType.getDescribe().isCreateable())
			{
				insert lcat1;
				insert lcat2;
			}

			EIT__c eit27 = new EIT__c();
			eit27.Name = 'Email (Opened)';
			eit27.Category__c = lcat1.Id;
			eit27.CustomTimelineObject__c = 'Lead';
			eit27.DescriptionFieldPath__c = 'TaskId.';
			eit27.DescriptionField__c = 'Task.Description';
			eit27.EndTimeValue__c = 'FirstOpenDate';
			eit27.ExecuteAsSubquery__c = true;
			eit27.HoverField__c = 'EmailTemplateName';
			eit27.InclusionField__c = 'FirstOpenDate';
			eit27.ObjectType__c = 'EmailStatus';
			eit27.Order__c = 1;
			eit27.ParentAccountIDField__c = 'EmailStatuses';
			eit27.RecordIDField__c = 'TaskId';
			eit27.RecordLimit__c = 50;
			eit27.RecordNameFieldPath__c = 'TaskId.';
			eit27.RecordNameField__c = 'Task.Subject';
			eit27.StartTimeValuePath__c = 'TaskId.';
			eit27.StartTimeValue__c = 'Task.ActivityDate';
			eit27.TextColor__c = 'green';
			eit27.Icon__c = '/resource/slt__Resources/SFDC_mail_icon.png';
			eit27.Image__c = '/resource/slt__Resources/SFDC_mail_image.png';
			eit27.TapeImage__c = '/resource/slt__Resources/tape_green_light_stripes.png';
			eit27.TapeRepeat__c = 'repeat';
			eit27.Description__c = 'Example of an opened email activity tracker for HTML emails. Uses an inclusion field of FirstOpenDate. Uses the associated task activity date and activity Id to override Activity History.';
			if (eitOwner) eit27.put('OwnerId', OwnerId);
			eits.add(eit27);

			EIT__c eit28 = new EIT__c();
			eit28.Name = 'Email';
			eit28.Category__c = lcat1.Id;
			eit28.CustomTimelineObject__c = 'Lead';
			eit28.DescriptionFieldPath__c = 'TaskId.';
			eit28.DescriptionField__c = 'Task.Description';
			eit28.ExecuteAsSubquery__c = true;
			eit28.HoverField__c = 'EmailTemplateName';
			eit28.ObjectType__c = 'EmailStatus';
			eit28.Order__c = 2;
			eit28.ParentAccountIDField__c = 'EmailStatuses';
			eit28.RecordIDField__c = 'TaskId';
			eit28.RecordLimit__c = 50;
			eit28.RecordNameFieldPath__c = 'TaskId.';
			eit28.RecordNameField__c = 'Task.Subject';
			eit28.StartTimeValuePath__c = 'TaskId.';
			eit28.StartTimeValue__c = 'Task.ActivityDate';
			eit28.Icon__c = '/resource/slt__Resources/SFDC_mail_icon.png';
			eit28.Image__c = '/resource/slt__Resources/SFDC_mail_image.png';
			eit28.Description__c = 'Example of an email activity tracker for emails. Uses the associated task activity date and activity Id to override Activity History.';
			if (eitOwner) eit28.put('OwnerId', OwnerId);
			eits.add(eit28);

			EIT__c eit29 = new EIT__c();
			eit29.Name = 'Activity History';
			eit29.Category__c = lcat1.Id;
			eit29.CustomTimelineObject__c = 'Lead';
			eit29.DescriptionField__c = 'Description';
			eit29.EndTimeValue__c = 'EndDateTime';
			eit29.ExecuteAsSubquery__c = true;
			eit29.HoverField__c = 'Status';
			eit29.ObjectType__c = 'ActivityHistory';
			eit29.Order__c = 3;
			eit29.ParentAccountIDField__c = 'ActivityHistories';
			eit29.RecordIDField__c = 'Id';
			eit29.RecordLimit__c = 50;
			eit29.RecordNameField__c = 'Subject';
			eit29.StartTimeValue__c = 'ActivityDate';
			eit29.Icon__c = '/resource/slt__Resources/phone_icon.png';
			eit29.Image__c = '/resource/slt__Resources/phone_image.png';
			eit29.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit29.TapeRepeat__c = 'repeat';
			eit29.Description__c = 'Example of an Activity History tracker';
			if (eitOwner) eit29.put('OwnerId', OwnerId);
			eits.add(eit29);

			EIT__c eit30 = new EIT__c();
			eit30.Name = 'Open Activities';
			eit30.Category__c = lcat1.Id;
			eit30.CustomTimelineObject__c = 'Lead';
			eit30.DescriptionField__c = 'Description';
			eit30.EndTimeValue__c = 'EndDateTime';
			eit30.ExecuteAsSubquery__c = true;
			eit30.HoverField__c = 'Status';
			eit30.ObjectType__c = 'OpenActivity';
			eit30.Order__c = 4;
			eit30.ParentAccountIDField__c = 'OpenActivities';
			eit30.RecordIDField__c = 'Id';
			eit30.RecordLimit__c = 50;
			eit30.RecordNameField__c = 'Subject';
			eit30.StartTimeValue__c = 'ActivityDate';
			eit30.Icon__c = '/resource/slt__Resources/clock_icon.png';
			eit30.Image__c = '/resource/slt__Resources/clock_image.png';
			eit30.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit30.TapeRepeat__c = 'repeat';
			eit30.Description__c = 'Example of an Open Activity tracker';
			if (eitOwner) eit30.put('OwnerId', OwnerId);
			eits.add(eit30);

			EIT__c eit31 = new EIT__c();
			eit31.Name = 'Attachments';
			eit31.Category__c = lcat1.Id;
			eit31.CustomTimelineObject__c = 'Lead';
			eit31.DescriptionField__c = 'Description';
			eit31.ExecuteAsSubquery__c = false;
			eit31.HoverField__c = 'ContentType';
			eit31.ObjectType__c = 'Attachment';
			eit31.Order__c = 5;
			eit31.ParentAccountIDField__c = 'ParentId';
			eit31.RecordIDField__c = 'Id';
			eit31.RecordLimit__c = 50;
			eit31.RecordNameField__c = 'Name';
			eit31.StartTimeValue__c = 'CreatedDate';
			eit31.Icon__c = '/resource/slt__Resources/SFDC_box_icon.png';
			eit31.Image__c = '/resource/slt__Resources/SFDC_box_image.png';
			eit31.Description__c = 'Example of an Attachment tracker.';
			if (eitOwner) eit31.put('OwnerId', OwnerId);
			eits.add(eit31);

			EIT__c eit32 = new EIT__c();
			eit32.Name = 'Campaign History (Responded)';
			eit32.Category__c = lcat2.Id;
			eit32.CustomTimelineObject__c = 'Lead';
			eit32.DescriptionFieldPath__c = 'CampaignId.';
			eit32.DescriptionField__c = 'Campaign.Description';
			eit32.EndTimeValue__c = 'FirstRespondedDate';
			eit32.ExecuteAsSubquery__c = false;
			eit32.HoverField__c = 'Status';
			eit32.InclusionField__c = 'HasResponded';
			eit32.ObjectType__c = 'CampaignMember';
			eit32.Order__c = 6;
			eit32.ParentAccountIDField__c = 'LeadId';
			eit32.RecordIDField__c = 'Id';
			eit32.RecordLimit__c = 50;
			eit32.RecordNameFieldPath__c = 'CampaignId.';
			eit32.RecordNameField__c = 'Campaign.Name';
			eit32.TextColor__c = 'green';
			eit32.StartTimeValue__c = 'CreatedDate';
			eit32.Icon__c = '/resource/slt__Resources/smiley_happy_icon.png';
			eit32.Image__c = '/resource/slt__Resources/smiley_happy_image.png';
			eit32.TapeImage__c = '/resource/slt__Resources/tape_green_stripes.png';
			eit32.TapeRepeat__c = 'repeat';
			eit32.Description__c = 'Example of a Campaign History tracker - those without a First Responded Date get captured by the following tracker';
			if (eitOwner) eit32.put('OwnerId', OwnerId);
			eits.add(eit32);

			EIT__c eit33 = new EIT__c();
			eit33.Name = 'Campaign History (No Response)';
			eit33.Category__c = lcat2.Id;
			eit33.CustomTimelineObject__c = 'Lead';
			eit33.DescriptionFieldPath__c = 'CampaignId.';
			eit33.DescriptionField__c = 'Campaign.Description';
			eit33.ExecuteAsSubquery__c = false;
			eit33.HoverField__c = 'Status';
			eit33.ObjectType__c = 'CampaignMember';
			eit33.Order__c = 7;
			eit33.ParentAccountIDField__c = 'LeadId';
			eit33.RecordIDField__c = 'Id';
			eit33.RecordLimit__c = 50;
			eit33.RecordNameFieldPath__c = 'CampaignId.';
			eit33.RecordNameField__c = 'Campaign.Name';
			eit33.StartTimeValue__c = 'CreatedDate';
			eit33.Icon__c = '/resource/slt__Resources/SFDC_star_icon.png';
			eit33.Image__c = '/resource/slt__Resources/SFDC_star_image.png';
			eit33.Description__c = 'Example of a Campaign History tracker - those with a First Responded Date get captured by the previous tracker';
			if (eitOwner) eit33.put('OwnerId', OwnerId);
			eits.add(eit33);

			EIT__c eit34 = new EIT__c();
			eit34.Name = 'Lead Created';
			// eit34.Category__c = lcat1.Id;
			eit34.CustomTimelineObject__c = 'Lead';
			eit34.DescriptionField__c = 'Description';
			eit34.ExecuteAsSubquery__c = false;
			eit34.HoverField__c = 'LeadSource';
			eit34.ObjectType__c = 'Lead';
			eit34.Order__c = 8;
			eit34.ParentAccountIDField__c = 'Id';
			eit34.RecordIDField__c = 'Id';
			eit34.RecordLimit__c = 50;
			eit34.RecordNameField__c = 'Name';
			eit34.StartTimeValue__c = 'CreatedDate';
			eit34.Icon__c = '/resource/slt__Resources/SFDC_redcross_icon.png';
			eit34.Image__c = '/resource/slt__Resources/SFDC_lead_image.png';
			eit34.Description__c = 'Example of an self-refential record start time.';
			if (eitOwner) eit34.put('OwnerId', OwnerId);
			eits.add(eit34);

			//
			//  create Opportunity trackers
			//

			Category__c ocat1 = new Category__c();
			ocat1.Name = 'Activities';
			ocat1.CustomTimelineObject__c = 'Opportunity';
			ocat1.DefaultVisibility__c = true;
			if (catOwner) ocat1.put('OwnerId', OwnerId);
			if (Category__c.SObjectType.getDescribe().isCreateable())
				insert ocat1;

			EIT__c eit35 = new EIT__c();
			eit35.Name = 'Activity History';
			eit35.Category__c = ocat1.Id;
			eit35.CustomTimelineObject__c = 'Opportunity';
			eit35.DescriptionField__c = 'Description';
			eit35.EndTimeValue__c = 'EndDateTime';
			eit35.ExecuteAsSubquery__c = true;
			eit35.HoverField__c = 'Status';
			eit35.ObjectType__c = 'ActivityHistory';
			eit35.Order__c = 1;
			eit35.ParentAccountIDField__c = 'ActivityHistories';
			eit35.RecordIDField__c = 'Id';
			eit35.RecordLimit__c = 50;
			eit35.RecordNameField__c = 'Subject';
			eit35.StartTimeValue__c = 'ActivityDate';
			eit35.Icon__c = '/resource/slt__Resources/phone_icon.png';
			eit35.Image__c = '/resource/slt__Resources/phone_image.png';
			eit35.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit35.TapeRepeat__c = 'repeat';
			eit35.Description__c = 'Example of an Activity History tracker';
			if (eitOwner) eit35.put('OwnerId', OwnerId);
			eits.add(eit35);

			EIT__c eit36 = new EIT__c();
			eit36.Name = 'Open Activities';
			eit36.Category__c = ocat1.Id;
			eit36.CustomTimelineObject__c = 'Opportunity';
			eit36.DescriptionField__c = 'Description';
			eit36.EndTimeValue__c = 'EndDateTime';
			eit36.ExecuteAsSubquery__c = true;
			eit36.HoverField__c = 'Status';
			eit36.ObjectType__c = 'OpenActivity';
			eit36.Order__c = 2;
			eit36.ParentAccountIDField__c = 'OpenActivities';
			eit36.RecordIDField__c = 'Id';
			eit36.RecordLimit__c = 50;
			eit36.RecordNameField__c = 'Subject';
			eit36.StartTimeValue__c = 'ActivityDate';
			eit36.Icon__c = '/resource/slt__Resources/clock_icon.png';
			eit36.Image__c = '/resource/slt__Resources/clock_image.png';
			eit36.TapeImage__c = '/resource/slt__Resources/tape_blue_light_stripes.png';
			eit36.TapeRepeat__c = 'repeat';
			eit36.Description__c = 'Example of an Open Activity tracker';
			if (eitOwner) eit36.put('OwnerId', OwnerId);
			eits.add(eit36);

			EIT__c eit37 = new EIT__c();
			eit37.Name = 'Stage History';
			// eit37.Category__c = ocat1.Id;
			eit37.CustomTimelineObject__c = 'Opportunity';
			eit37.DescriptionField__c = 'ForecastCategory';
			eit37.ExecuteAsSubquery__c = false;
			eit37.HoverField__c = 'Amount';
			eit37.ObjectType__c = 'OpportunityHistory';
			eit37.Order__c = 3;
			eit37.ParentAccountIDField__c = 'OpportunityId';
			eit37.RecordIDField__c = 'OpportunityId';
			eit37.RecordLimit__c = 50;
			eit37.RecordNameField__c = 'StageName';
			eit37.StartTimeValue__c = 'CreatedDate';
			eit37.Icon__c = '/resource/slt__Resources/SFDC_pencil_icon.png';
			eit37.Image__c = '/resource/slt__Resources/SFDC_opportunity_image.png';
			eit37.Description__c = 'Example Opportunity Stage history tracker';
			if (eitOwner) eit37.put('OwnerId', OwnerId);
			eits.add(eit37);

			EIT__c eit38 = new EIT__c();
			eit38.Name = 'Attachments';
			eit38.Category__c = ocat1.Id;
			eit38.CustomTimelineObject__c = 'Opportunity';
			eit38.DescriptionField__c = 'Description';
			eit38.ExecuteAsSubquery__c = false;
			eit38.HoverField__c = 'ContentType';
			eit38.ObjectType__c = 'Attachment';
			eit38.Order__c = 4;
			eit38.ParentAccountIDField__c = 'ParentId';
			eit38.RecordIDField__c = 'Id';
			eit38.RecordLimit__c = 50;
			eit38.RecordNameField__c = 'Name';
			eit38.StartTimeValue__c = 'CreatedDate';
			eit38.Icon__c = '/resource/slt__Resources/SFDC_box_icon.png';
			eit38.Image__c = '/resource/slt__Resources/SFDC_box_image.png';
			eit38.Description__c = 'Example of an Attachments tracker.';
			if (eitOwner) eit38.put('OwnerId', OwnerId);
			eits.add(eit38);

			EIT__c eit39 = new EIT__c();
			eit39.Name = 'Opportunity Created';
			// eit39.Category__c = ocat1.Id;
			eit39.CustomTimelineObject__c = 'Opportunity';
			eit39.DescriptionField__c = 'Description';
			eit39.ExecuteAsSubquery__c = false;
			eit39.HoverField__c = 'Amount';
			eit39.ObjectType__c = 'Opportunity';
			eit39.Order__c = 5;
			eit39.ParentAccountIDField__c = 'Id';
			eit39.RecordIDField__c = 'Id';
			eit39.RecordLimit__c = 50;
			eit39.RecordNameField__c = 'Name';
			eit39.StartTimeValue__c = 'CreatedDate';
			eit39.Icon__c = '/resource/slt__Resources/SFDC_redcross_icon.png';
			eit39.Image__c = '/resource/slt__Resources/SFDC_opportunity_image.png';
			eit39.Description__c = 'Example of a self-referntial record start time.';
			if (eitOwner) eit39.put('OwnerId', OwnerId);
			eits.add(eit39);

			EIT__c eit40 = new EIT__c();
			eit40.Name = 'Opportunity Won';
			// eit40.Category__c = ocat1.Id;
			eit40.CustomTimelineObject__c = 'Opportunity';
			eit40.DescriptionField__c = 'Description';
			eit40.ExecuteAsSubquery__c = false;
			eit40.HoverField__c = 'NextStep';
			eit40.InclusionField__c = 'IsWon';
			eit40.ObjectType__c = 'Opportunity';
			eit40.Order__c = 6;
			eit40.ParentAccountIDField__c = 'Id';
			eit40.RecordIDField__c = 'Id';
			eit40.RecordLimit__c = 50;
			eit40.RecordNameField__c = 'StageName';
			eit40.StartTimeValue__c = 'CloseDate';
			eit40.Icon__c = '/resource/slt__Resources/smiley_happy_icon.png';
			eit40.Image__c = '/resource/slt__Resources/smiley_happy_image.png';
			eit40.Description__c = 'Example of a self-referential record close time. Uses "IsWon" as an inclusion field to override lower trackers. Although it uses the same ID, it does not conflict with Opportunity Created because the time is different.';
			if (eitOwner) eit40.put('OwnerId', OwnerId);
			eits.add(eit40);

			EIT__c eit41 = new EIT__c();
			eit41.Name = 'Opportunity Lost';
			// eit41.Category__c = ocat1.Id;
			eit41.CustomTimelineObject__c = 'Opportunity';
			eit41.DescriptionField__c = 'Description';
			eit41.ExecuteAsSubquery__c = false;
			eit41.HoverField__c = 'NextStep';
			eit41.InclusionField__c = 'IsClosed';
			eit41.ObjectType__c = 'Opportunity';
			eit41.Order__c = 7;
			eit41.ParentAccountIDField__c = 'Id';
			eit41.RecordIDField__c = 'Id';
			eit41.RecordLimit__c = 50;
			eit41.RecordNameField__c = 'StageName';
			eit41.StartTimeValue__c = 'CloseDate';
			eit41.Icon__c = '/resource/slt__Resources/smiley_unhappy_icon.png';
			eit41.Image__c = '/resource/slt__Resources/smiley_unhappy_image.png';
			eit41.Description__c = 'Example of a self-referential record close time. Uses "IsClosed" as an inclusion field to override lower trackers. Although it uses the same ID, it does not conflict with Opportunity Created because the time is different.';
			if (eitOwner) eit41.put('OwnerId', OwnerId);
			eits.add(eit41);

			EIT__c eit42 = new EIT__c();
			eit42.Name = 'Opportunity Expected Close';
			// eit42.Category__c = ocat1.Id;
			eit42.CustomTimelineObject__c = 'Opportunity';
			eit42.DescriptionField__c = 'Description';
			eit42.ExecuteAsSubquery__c = false;
			eit42.HoverField__c = 'NextStep';
			eit42.ObjectType__c = 'Opportunity';
			eit42.Order__c = 8;
			eit42.ParentAccountIDField__c = 'Id';
			eit42.RecordIDField__c = 'Id';
			eit42.RecordLimit__c = 50;
			eit42.RecordNameField__c = 'Name';
			eit42.StartTimeValue__c = 'CloseDate';
			eit42.Icon__c = '/resource/slt__Resources/money_icon.png';
			eit42.Image__c = '/resource/slt__Resources/money_image.png';
			eit42.Description__c = 'Example of a self-referential record close time. Although it uses the same ID, it does not conflict with Opportunity Created because the time is different.';
			if (eitOwner) eit42.put('OwnerId', OwnerId);
			eits.add(eit42);

			if (EIT__c.SObjectType.getDescribe().isCreateable())
				insert eits;
		}
	}
}