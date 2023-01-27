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

/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */

@isTest
private class UnitTest
{

	static testMethod void TestConfig()
	{
		//
		//  test Config class
		//

		PageReference ref;

		Category__c cat1 = new Category__c();
		cat1.Name = 'Cat 1';
		cat1.DefaultVisibility__c = true;
		insert cat1;

		Category__c cat2 = new Category__c();
		cat2.Name = 'Cat 2';
		cat2.DefaultVisibility__c = false;
		insert cat2;

		Config eitc = new Config();
		eitc.getobjs();
		eitc.getTimelineObjects();
		List<SelectOption> tls = eitc.Timelines;
		System.assertEquals(0, eitc.TimelineCount);
		System.assertNotEquals(null, eitc.eit);

		eitc.eit.ObjectType__c = 'Contact';
		eitc.eit.Category__c = cat1.Id;

		eitc.UpdateAllFields();
		eitc.save();

		eitc.eit.ParentAccountIDField__c = 'AccountId';
		eitc.UpdateAllFields();
		System.assertNotEquals(null, eitc.InclusionFields);
		System.assertNotEquals(null, eitc.RecordIDFields);
		System.assertNotEquals(null, eitc.ParentContactIDFields);
		System.assertNotEquals(null, eitc.ParentAccountIDFields);
		System.assertNotEquals(null, eitc.RecordNameFields);
		System.assertNotEquals(null, eitc.HoverFields);
		System.assertNotEquals(null, eitc.DescriptionFields);
		System.assertNotEquals(null, eitc.CustSatFields);
		System.assertNotEquals(null, eitc.StartTimeFields);
		System.assertNotEquals(null, eitc.EndTimeFields);
		System.assertNotEquals(null, eitc.eit);

		eitc.eit.ParentContactIDField__c = 'ReportsToId';
		eitc.UpdateAllFields();
		eitc.save();

		eitc.eit.ParentAccountIDField__c = 'Account.';
		eitc.eit.ParentAccountIDFieldPath__c = 'Account.';
		eitc.eit.ParentContactIDField__c = 'ReportsTo.';
		eitc.eit.ParentContactIDFieldPath__c = 'ReportsTo.';
		eitc.UpdateAllFields();

		System.assertNotEquals(null, eitc.ParentContactIDFields);
		System.assertNotEquals(null, eitc.ParentAccountIDFields);

		eitc.eit.ParentAccountIDField__c = 'Account.Id';
		eitc.eit.ParentAccountIDFieldPath__c = 'Account.';
		eitc.eit.ParentContactIDField__c = 'ReportsTo.Id';
		eitc.eit.ParentContactIDFieldPath__c = 'ReportsTo.';
		eitc.UpdateParentAccountIDFields();
		eitc.UpdateParentContactIDFields();

		System.assertNotEquals(null, eitc.ParentContactIDFields);
		System.assertNotEquals(null, eitc.ParentAccountIDFields);

		eitc.eit.RecordTypes2__c = null;
		eitc.eit.InclusionField__c = 'ReportsTo.';
		eitc.eit.InclusionFieldPath__c = 'ReportsTo.';
		eitc.eit.AccountContactMatching__c = 'CTX';
		eitc.eit.RecordNameField__c = 'ReportsTo.';
		eitc.eit.RecordNameFieldPath__c = 'ReportsTo.';
		eitc.eit.HoverField__c = 'ReportsTo.';
		eitc.eit.HoverFieldPath__c = 'ReportsTo.';
		eitc.eit.DescriptionField__c = 'ReportsTo.';
		eitc.eit.DescriptionFieldPath__c = 'ReportsTo.';
		eitc.eit.CustSatField__c = 'ReportsTo.';
		eitc.eit.CustSatFieldPath__c = 'ReportsTo.';
		eitc.eit.StartTimeValue__c = 'ReportsTo.';
		eitc.eit.StartTimeValuePath__c = 'ReportsTo.';
		eitc.eit.EndTimeValue__c = 'ReportsTo.';
		eitc.eit.EndTimeValuePath__c = 'ReportsTo.';
		eitc.eit.ExecuteAsSubquery__c = false;
		eitc.UpdateInclusionFields();
		eitc.UpdateRecordNameFields();
		eitc.UpdateHoverFields();
		eitc.UpdateDescriptionFields();
		eitc.UpdateParentContactIDFields();
		eitc.UpdateCustSatFields();
		eitc.UpdateStartTimeFields();
		eitc.UpdateEndTimeFields();

		System.assertNotEquals(null, eitc.InclusionFields);
		System.assertNotEquals(null, eitc.RecordIDFields);
		System.assertNotEquals(null, eitc.ParentContactIDFields);
		System.assertNotEquals(null, eitc.ParentAccountIDFields);
		System.assertNotEquals(null, eitc.RecordNameFields);
		System.assertNotEquals(null, eitc.HoverFields);
		System.assertNotEquals(null, eitc.DescriptionFields);
		System.assertNotEquals(null, eitc.CustSatFields);
		System.assertNotEquals(null, eitc.StartTimeFields);
		System.assertNotEquals(null, eitc.EndTimeFields);
		System.assertNotEquals(null, eitc.eit);

		eitc.eit.ExecuteAsSubquery__c = true;
		System.assertNotEquals(null, eitc.AccountRelationships);
		System.assertEquals(null, eitc.ContactRelationships);
		System.assertNotEquals(null, eitc.Categories);
		System.assertEquals(0, eitc.eitcount);
		System.assertEquals(true, eitc.RecordTypeOptionsAvailable);

		eitc.eit.Id = null;
		eitc.eit.Order__c = 2;
		eitc.save();
		EIT__c temp = eitc.eit;
		eitc.order = 1;
		eitc.eitID = eitc.eit.Id;
		eitc.reorder();
		eitc.eit = temp;
		eitc.eit.Order__c = 1;
		eitc.eitID = eitc.eit.Id;
		eitc.remove();
	}


	static testMethod void TestTimeline()
	{
		//
		//  test Timeline class
		//

		PageReference ref;

		Category__c cat1 = new Category__c();
		cat1.Name = 'Cat 1';
		cat1.DefaultVisibility__c = true;
		insert cat1;

		Category__c cat2 = new Category__c();
		cat2.Name = 'Cat 2';
		cat2.DefaultVisibility__c = false;
		insert cat2;

		Account a1 = new Account();
		a1.Name = 'Test Account 1';
		a1.Description = 'Test Account 1';
		a1.BillingCity = 'City 1';
		insert a1;

		System.assertEquals(Timeline.personAccountsEnabled, false);

		Account a2 = new Account();
		a2.Name = 'Test Account 2';
		a2.Description = 'Test Account 2';
		a2.BillingCity = 'City';
		a2.ParentId = a1.Id;
		insert a2;

		Opportunity o1 = new Opportunity();
		o1.Name = 'Test Opp 1';
		o1.CloseDate = Date.today();
		o1.StageName = 'Closed Won';
		o1.Probability = 100;
		o1.Amount = 19.5;
		o1.AccountId = a2.Id;
		insert o1;

		Opportunity o2 = new Opportunity();
		o2.Name = 'Test Opp 1';
		o2.CloseDate = Date.today();
		o2.StageName = 'Prospecting';
		o2.Probability = 40;
		o2.Amount = 19.5;
		o2.AccountId = a2.Id;
		insert o2;

		Contact c1 = new Contact();
		c1.FirstName = 'First1';
		c1.LastName = 'Last1';
		c1.AccountId = a2.Id;
		c1.Title = 'Title1';
		insert c1;

		Contact c2 = new Contact();
		c2.FirstName = 'First2';
		c2.LastName = 'Last2';
		c2.AccountId = a2.Id;
		c2.Title = 'Title';
		c2.ReportsToId = c1.Id;
		insert c2;

		a2.BillingCity = 'City 2';
		update a2;

		c2.Title = 'Title2';
		update c2;

		EIT__c eit1 = new EIT__c();
		eit1.Name = 'Test EIT 1';
		eit1.Active__c = true;
		eit1.Description__c = 'Test EIT 1';
		eit1.ObjectType__c = 'Contact';
		eit1.ParentAccountIDField__c = 'AccountId';
		eit1.ParentContactIDField__c = 'ReportsTo.Id';
		eit1.AccountContactMatching__c = 'OR';
		eit1.RecordNameField__c = 'FirstName';
		eit1.HoverField__c = 'Title';
		eit1.DescriptionField__c = 'LastName';
		eit1.StartTimeValue__c = 'CreatedDate';
		eit1.EndTimeValue__c = 'LastModifiedDate';
		eit1.Category__c = cat1.Id;
		eit1.Color__c = 'green';
		insert eit1;

		EIT__c eit2 = new EIT__c();
		eit2.Name = 'Test EIT 2';
		eit2.Active__c = true;
		eit2.Description__c = 'Test EIT 2';
		eit2.ObjectType__c = 'Account';
		eit2.ParentAccountIDField__c = 'Parent.Id';
		eit2.RecordNameField__c = 'Name';
		eit2.HoverField__c = 'BillingCity';
		eit2.DescriptionField__c = 'Description';
		eit2.StartTimeValue__c = 'LastModifiedDate';
		eit2.EndTimeValue__c = 'CreatedDate';
		eit2.Category__c = cat2.Id;
		eit2.Color__c = 'red';
		insert eit2;

		EIT__c eit3 = new EIT__c();
		eit3.Name = 'Test EIT 3';
		eit3.Active__c = true;
		eit3.Description__c = 'Test EIT 3';
		eit3.ObjectType__c = 'Contact';
		eit3.ParentAccountIDField__c = 'Account.ParentId';
		eit3.ParentContactIDField__c = 'ReportsTo.Id';
		eit3.AccountContactMatching__c = 'AND';
		eit3.RecordNameField__c = 'FirstName';
		eit3.HoverField__c = 'LastName';
		eit3.DescriptionField__c = 'LastName';
		eit3.StartTimeValue__c = 'CreatedDate';
		eit3.EndTimeValue__c = 'LastModifiedDate';
		eit3.Category__c = cat1.Id;
		eit3.Color__c = 'green';
		insert eit3;

		EIT__c eit4 = new EIT__c();
		eit4.Name = 'Test EIT 4';
		eit4.Active__c = true;
		eit4.Description__c = 'Test EIT 4';
		eit4.ObjectType__c = 'Contact';
		eit4.ParentAccountIDField__c = 'AccountId';
		eit4.ParentContactIDField__c = 'ReportsToId';
		eit4.AccountContactMatching__c = 'ORC';
		eit4.RecordNameField__c = 'FirstName';
		eit4.StartTimeValue__c = 'CreatedDate';
		insert eit4;

		EIT__c eit5 = new EIT__c();
		eit5.Name = 'Test EIT 5';
		eit5.Active__c = true;
		eit5.Description__c = 'Test EIT 5';
		eit5.ObjectType__c = 'Contact';
		eit5.ParentAccountIDField__c = 'AccountId';
		eit5.ParentContactIDField__c = 'ReportsToId';
		eit5.AccountContactMatching__c = 'ORA';
		eit5.RecordNameField__c = 'FirstName';
		eit5.HoverField__c = 'LastName';
		eit5.DescriptionField__c = 'LastName';
		eit5.StartTimeValue__c = 'CreatedDate';
		insert eit5;

		EIT__c eit6 = new EIT__c();
		eit6.Name = 'Test EIT 6';
		eit6.Active__c = true;
		eit6.Description__c = 'Test EIT 6';
		eit6.ObjectType__c = 'Contact';
		eit6.ParentAccountIDField__c = 'Contacts';
		eit6.ExecuteAsSubquery__c = true;
		eit6.AccountContactMatching__c = 'OR';
		eit6.RecordNameField__c = 'FirstName';
		eit6.HoverField__c = 'LastName';
		eit6.DescriptionField__c = 'LastName';
		eit6.StartTimeValue__c = 'CreatedDate';
		insert eit6;

		EIT__c eit7 = new EIT__c();
		eit7.Name = 'Test EIT 7';
		eit7.Active__c = true;
		eit7.Description__c = 'Test EIT 7';
		eit7.ObjectType__c = 'Attachment';
		eit7.ParentContactIDField__c = 'Attachments';
		eit7.ParentAccountIDField__c = 'Attachments';
		eit7.ExecuteAsSubquery__c = true;
		eit7.AccountContactMatching__c = 'OR';
		eit7.RecordNameField__c = 'Name';
		eit7.HoverField__c = 'ContentType';
		eit7.DescriptionField__c = 'Description';
		eit7.StartTimeValue__c = 'CreatedDate';
		insert eit7;

		EIT__c eit8 = new EIT__c();
		eit8.Name = 'Test EIT 8';
		eit8.Active__c = true;
		eit8.Description__c = 'Test EIT 8';
		eit8.ObjectType__c = 'Attachment';
		eit8.ParentContactIDField__c = 'ParentId';
		eit8.ParentAccountIDField__c = 'ParentId';
		eit8.AccountContactMatching__c = 'OR';
		eit8.RecordNameField__c = 'Name';
		eit8.HoverField__c = 'ContentType';
		eit8.DescriptionField__c = 'Description';
		eit8.StartTimeValue__c = 'CreatedDate';
		insert eit8;

		EIT__c eit9 = new EIT__c();
		eit9.Name = 'Won Opportunities';
		eit9.Active__c = true;
		eit9.ObjectType__c = 'Opportunity';
		eit9.ParentAccountIDField__c = 'AccountId';
		eit9.AccountContactMatching__c = 'CTX';
		eit9.RecordNameField__c = 'Name';
		eit9.HoverField__c = 'Amount';
		eit9.DescriptionField__c = 'Description';
		eit9.InclusionField__c = 'IsWon';
		eit9.StartTimeValue__c = 'CloseDate';
		insert eit9;

		EIT__c eit10 = new EIT__c();
		eit10.Name = 'Open Opportunities';
		eit10.Active__c = true;
		eit10.ObjectType__c = 'Opportunity';
		eit10.ParentAccountIDField__c = 'AccountId';
		eit10.AccountContactMatching__c = 'CTX';
		eit10.RecordNameField__c = 'Name';
		eit10.HoverField__c = 'Probability';
		eit10.DescriptionField__c = 'Description';
		eit10.InclusionField__c = 'Probability';
		eit10.StartTimeValue__c = 'CloseDate';
		insert eit10;

		ref = new PageReference(Page.Timeline.getUrl() + '?id=' + c2.Id);
		Test.setCurrentPage(ref);
		Timeline eitt1 = new Timeline();

		System.assertNotEquals(null, eitt1.EventCategories);
		System.assertNotEquals(null, eitt1.Timezone);
		System.assertNotEquals(null, eitt1.JSONEventsString);
		System.assertEquals(eitt1.PrimaryID.ID, c2.Id);

		ref = new PageReference(Page.Timeline.getUrl() + '?id=' + a2.Id);
		Test.setCurrentPage(ref);
		Timeline eitt2 = new Timeline();

		System.assertNotEquals(null, eitt2.JSONEventsString);
		System.assertEquals(eitt2.PrimaryID.ID, a2.Id);

		ref = new PageReference(Page.Timeline.getUrl() + '?id=' + a2.Id + '&xid=' + c2.Id);
		Test.setCurrentPage(ref);
		Timeline eitt3 = new Timeline();

		System.assertNotEquals(null, eitt3.JSONEventsString);
		System.assertEquals(eitt3.PrimaryID.ID, a2.Id);

		ref = new PageReference(Page.Timeline.getUrl() + '?xid=' + a2.Id + '&id=' + c2.Id);
		Test.setCurrentPage(ref);
		Timeline eitt4 = new Timeline();

		System.assertNotEquals(null, eitt4.JSONEventsString);
		System.assertEquals(eitt4.ContextID.ID, a2.Id);
	}



	static testMethod void TestInstall()
	{
		//
		//  test Install class
		//
		Install install = new Install();
		Test.testInstall(install, null);
		System.assertEquals(install, install);

	}

}