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



public with sharing class Config
{
	public String eitID
	{
		get
		{
			if (eitID == null)
			{
				String eid = ApexPages.currentPage().getParameters().get('id');
//				if (eid != null && eid != '') eitID = Id.valueOf(eid);
				if (eid != null && eid != '') eitID = eid;
			}
			return eitID;
		}
		set;
	}

	private Boolean TimelineObjectSet = false;

	public String TimelineObject
	{
		get
		{
			if (TimelineObjectSet == false)
			{
				String tmob = ApexPages.currentPage().getParameters().get('timeline');
				if (tmob == '') TimelineObject = null;
				else TimelineObject = tmob;
			}
			return TimelineObject;
		}
		set
		{
			TimelineObject = value;
			TimelineObjectSet = true;
			TimelineObjectLabel = null;
		}
	}

	public String TimelineObjectLabel
	{
		get
		{
			if (TimelineObjectLabel == null)
			{
				if (TimelineObject == null || TimelineObject == '') TimelineObjectLabel = 'Customer';
				else
				{
						Schema.DescribeSObjectResult objDesc;
						Schema.SObjectType objType = globalDescription.get(TimelineObject.toLowerCase());
						if (objType != null) objDesc = objType.getDescribe();
						if (objDesc != null)
							TimelineObjectLabel = objDesc.getLabel();
						else
							TimelineObjectLabel = TimelineObject;
				}
			}
			return TimelineObjectLabel;
		}
		set;
	}

	public EIT__c eit
	{
		get
		{
			if (eit == null)
			{
				if (eitID == null || ((String)eitID) == '')
				{
					eit = new EIT__c();
					eit.Active__c = true;
					eit.CustomTimelineObject__c = TimelineObject;
					eit.RecordLimit__c = 50;
					String order = ApexPages.currentPage().getParameters().get('order');
					if (order != null && order != '' && order.isNumeric()) eit.Order__c = Integer.valueOf(order);
					return eit;
				}
				List<EIT__c> eits =
				[
					SELECT
						Id,
						Name,
						CustomTimelineObject__c,
						Active__c,
						Description__c,
						Order__c,
						ObjectType__c,
						ExecuteAsSubquery__c,
						RecordTypes2__c,
						RecordIDField__c,
						RecordIDFieldPath__c,
						InclusionField__c,
						InclusionFieldPath__c,
						ParentContactIDField__c,
						ParentContactIDFieldPath__c,
						ParentAccountIDField__c,
						ParentAccountIDFieldPath__c,
						AccountContactMatching__c,
						RecordNameField__c,
						RecordNameFieldPath__c,
						HoverField__c,
						HoverFieldPath__c,
						DescriptionField__c,
						DescriptionFieldPath__c,
						CustSatField__c,
						CustSatFieldPath__c,
						CustSatWorst__c,
						CustSatBest__c,
						CustSatHalfLife__c,
						CustSatWeighting__c,
						CustSatEmptyNeutral__c,
						CustSatOnly__c,
						StartTimeValue__c,
						StartTimeValuePath__c,
						EndTimeValue__c,
						EndTimeValuePath__c,
						Category__c,
						RecordLimit__c,
						Color__c,
						TextColor__c,
						Icon__c,
						Image__c,
						TapeImage__c,
						TapeRepeat__c,
						OwnerId,
						CreatedDate,
						LastModifiedDate,
						LastModifiedById,
						SystemModstamp,
						IsDeleted
					FROM
						EIT__c
					WHERE
						Id = :eitID
				];
				if (eits != null && eits.size() > 0) eit = eits[0];
				if (eit != null)
				{
					if (eit.CustomTimelineObject__c != null && eit.CustomTimelineObject__c != '')
						TimelineObject = eit.CustomTimelineObject__c;
					if  (eit.RecordTypes2__c != null && eit.RecordTypes2__c.length() > 1)
					{
						for (String rt : eit.RecordTypes2__c.split(';'))
							if (rt != null && rt.length() > 1) recordTypes.add(rt);
					}
					if (eit.ExecuteAsSubquery__c == true)
					{
						Schema.DescribeSObjectResult objdesc = globalDescription.get(eit.ObjectType__c.toLowerCase()).getDescribe();
						if (!objdesc.isQueryable()) subqueryRequired = true;
					}
				}
			}
			return eit;

		}
		set;
	}

	public static List<SelectOption> selectOptionSortByLabel(List<SelectOption> selectOptionsToSort)
	{
		if (selectOptionsToSort == null || selectOptionsToSort.size() <= 1)
			return selectOptionsToSort;

		List<SelectOption> lessSelectOption = new List<SelectOption>();
		List<SelectOption> greaterSelectOption = new List<SelectOption>();

		integer pivot = selectOptionsToSort.size() / 2;

		//  save the pivot and remove it from the selectOption list
		SelectOption pivotValue = selectOptionsToSort[pivot];
		selectOptionsToSort.remove(pivot);
		for (selectOption SO : selectOptionsToSort)
		{
			if (SO.getLabel() <= pivotValue.getLabel())
			{
				lessSelectOption.add(SO);
			}
			else if (SO.getLabel() > pivotValue.getLabel())
			{
				greaterSelectOption.add(SO);   
			}
		}
		List<SelectOption> SortedSelectOptions = new List<SelectOption>(); 
		sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
		sortedSelectOptions.add(pivotValue);
		sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
		return SortedSelectOptions;
	}

	public class eitwrapper
	{
		public EIT__c eit { get; set; }
		public String objectLabel { get; set; }
		public String recordTypesLabel { get; set; }
		public eitwrapper(EIT__c t)
		{
			eit = t;
			recordTypesLabel = '-';
			try
			{
				objectLabel = Schema.getGlobalDescribe().get(eit.ObjectType__c.toLowerCase()).getDescribe().getLabel();
			}
			catch (Exception e)
			{
				objectLabel = 'ERROR';
			}
		}		
	}

	public List<eitwrapper> eitwrappers
	{
		get
		{
			if (eitwrappers == null)
			{
				if (eits == null) return null;
				eitwrappers = new List<eitwrapper>();
				Set<Id> recTypes = new Set<Id>();
				for (EIT__c t : eits)
				{
					if (t.RecordTypes2__c != null && t.RecordTypes2__c.length() > 1)
					{
						for (String rt : t.RecordTypes2__c.split(';'))
							if (rt != null && rt.length() > 1 && !recTypes.contains(rt)) recTypes.add(rt);
					}
				}
				Map<Id, String> rtmap = new Map<Id, String>();
				if (recTypes.size() > 0)
				{
					List<RecordType> rts = [SELECT Id, Name FROM RecordType WHERE Id IN :recTypes];
					if (rts != null) for (RecordType rt : rts) rtmap.put(rt.Id, rt.Name);
				}
				for (EIT__c t : eits)
				{
					eitwrapper ew = new eitwrapper(t);
					if (t.RecordTypes2__c != null && t.RecordTypes2__c.length() > 1)
					{
						ew.recordTypesLabel = '';
						for (String rt : t.RecordTypes2__c.split(';'))
						{
							if (rt != null && rt.length() > 1)
							{
								String rectype = rtmap.get(rt);
								if (rectype == null || rectype == '') rectype = 'Master';
								ew.recordTypesLabel = ew.recordTypesLabel + (ew.recordTypesLabel == '' ? '' : '; ') + rectype;
							}
						}
					}
					eitwrappers.add(ew);
				}
			}
			return eitwrappers;
		}
		set;
	}

	static private SelectOption blankSelect()
	{
		SelectOption blank = new SelectOption('', ' ');
		blank.setDisabled(true);
		return blank;
	}

	public Integer eitcount
	{
		get
		{
			if (eitcount == null)
			{
				if (eitwrappers == null) return null;
				eitcount = eitwrappers.size();
			}
			return eitcount;
		}
		set;
	}

	public List<EIT__c> eits
	{
		get
		{
			if (eits == null)
			{
				eits =
				[
					SELECT
						Id,
						Name,
						CustomTimelineObject__c,
						Active__c,
						Description__c,
						Order__c,
						ObjectType__c,
						ExecuteAsSubquery__c,
						RecordTypes2__c,
						RecordIDField__c,
						RecordIDFieldPath__c,
						InclusionField__c,
						InclusionFieldPath__c,
						ParentContactIDField__c,
						ParentContactIDFieldPath__c,
						ParentAccountIDField__c,
						ParentAccountIDFieldPath__c,
						AccountContactMatching__c,
						RecordNameField__c,
						RecordNameFieldPath__c,
						HoverField__c,
						HoverFieldPath__c,
						DescriptionField__c,
						DescriptionFieldPath__c,
						CustSatField__c,
						CustSatFieldPath__c,
						CustSatWorst__c,
						CustSatBest__c,
						CustSatHalfLife__c,
						CustSatWeighting__c,
						CustSatEmptyNeutral__c,
						CustSatOnly__c,
						StartTimeValue__c,
						StartTimeValuePath__c,
						EndTimeValue__c,
						EndTimeValuePath__c,
						Category__c,
						Category__r.Name,
						RecordLimit__c,
						Color__c,
						TextColor__c,
						Icon__c,
						Image__c,
						TapeImage__c,
						TapeRepeat__c,
						OwnerId,
						CreatedDate,
						LastModifiedDate,
						LastModifiedById,
						SystemModstamp,
						IsDeleted
					FROM
						EIT__c
					WHERE
						CustomTimelineObject__c = :TimelineObject
					ORDER BY
						Order__c ASC
				];
			}
			return eits;
		}
		set;
	}

	public Config() 
	{	
	}

	public Config(ApexPages.StandardController stdController)
	{
		// this.eit = (EIT__c)stdController.getRecord();
	}

	public List<Category__c> EIT_Categories
	{
		get
		{
			if (EIT_Categories == null)
			{
				EIT_Categories =
				[
					SELECT
						Id,
						Name,
						DefaultVisibility__c,
						CustomTimelineObject__c
					FROM
						Category__c
					WHERE
						CustomTimelineObject__c = :TimelineObject
					ORDER BY
						Name ASC
				];
			}
			return EIT_Categories;
		}
		set;
	}

	public Integer categorycount
	{
		get
		{
			if (categorycount == null)
			{
				if (EIT_Categories == null) return null;
				categorycount = EIT_Categories.size();
			}
			return categorycount;
		}
		set;
	}

	public List<SelectOption> Categories
	{
		get
		{
			if (Categories == null)
			{
				Categories = new List<SelectOption>();
				if (EIT_Categories != null) for (Category__c cat : EIT_Categories)
					Categories.add(new SelectOption(cat.Id, cat.Name));
				if (Categories.size() > 0)
				{
					Categories.add(0, new SelectOption('', '- Choose a Category -'));
				}
				else Categories.add(new SelectOption('', '- No Categories Defined -'));
			}
			return Categories;
		}
		set;
	}

	public List<SelectOption> getobjs()
	{
		List<Schema.SObjectType> gd = globalDescription.Values();	
		List<SelectOption> objects = new List<SelectOption>();

		for (Schema.SObjectType f : gd)
		{
			if (objects.size() > 998) break;
			Schema.DescribeSObjectResult obj = f.getDescribe();
			String label = obj.getLabel();
			if (label.startsWith('Tag:') || label.startsWith('History:') || label.startsWith('Feed:') || label.startsWith('Share:')) continue;
			objects.add(new SelectOption(obj.getName(), label + (label.replace(' ','').equalsIgnoreCase(obj.getName()) ? '' : ' (' + obj.getName() + ')')));
		}
		objects = selectOptionSortByLabel(objects);
		objects.add(0, new SelectOption('', '- Choose an Object -'));
		return objects;
	}

	private Set<String> usedTimelines = new Set<String>();

	public Integer TimelineCount
	{
		get
		{
			if (TimelineCount == null)
			{
				if (Timelines != null && usedTimelines != null)
				{
					TimelineCount = usedTimelines.size();
				}
			}
			return TimelineCount;
		}
		set;
	}

	public List<SelectOption> Timelines
	{
		get
		{
			if (Timelines == null)
			{
				Timelines = new List<SelectOption>();
				Boolean found = false;
				List<AggregateResult> tls = new List<AggregateResult>();
				List<AggregateResult> tlsq;
				tlsq = [SELECT CustomTimelineObject__c, COUNT(Name) FROM EIT__c GROUP BY CustomTimelineObject__c ORDER BY CustomTimelineObject__c];
				if (tlsq != null) tls.addAll(tlsq);
				tlsq = [SELECT CustomTimelineObject__c, COUNT(Name) FROM Category__c GROUP BY CustomTimelineObject__c ORDER BY CustomTimelineObject__c];
				if (tlsq != null) tls.addAll(tlsq);
				for (AggregateResult tl : tls)
				{
					String timeline = (String)tl.get('slt__CustomTimelineObject__c');
					if (timeline != null && timeline != '')
					{
						if (usedTimelines.contains(timeline)) continue;
						usedTimelines.add(timeline);
						if (timeline == TimelineObject) found = true;
						Schema.DescribeSObjectResult objDesc;
						Schema.SObjectType objType = globalDescription.get(timeline.toLowerCase());
						if (objType != null) objDesc = objType.getDescribe();
						if (objDesc != null)
							timelines.add(new SelectOption(timeline, objDesc.getLabel() + ' Timeline'));
						else
							timelines.add(new SelectOption(timeline, timeline + ' Timeline'));
					}
				}
				if (!found && TimelineObject != null && TimelineObject != '' && TimelineObject != '+')
				{
					Schema.DescribeSObjectResult objDesc;
					Schema.SObjectType objType = globalDescription.get(TimelineObject.toLowerCase());
					if (objType != null) objDesc = objType.getDescribe();
					if (objDesc != null)
						Timelines.add(new SelectOption(TimelineObject, objDesc.getLabel() + ' Timeline'));
					else
						Timelines.add(new SelectOption(TimelineObject, TimelineObject + ' Timeline'));
				}
				Timelines = selectOptionSortByLabel(Timelines);
				if (Timelines.size() > 0)
					Timelines.add(0, new SelectOption('', 'Customer Timeline'));
				else
					Timelines.add(new SelectOption('', 'Customer Timeline'));			
				Timelines.add(blankSelect());
				Timelines.add(new SelectOption('+', 'Create New...'));
			}
			return Timelines;
		}
		set;
	}

	public List<SelectOption> getTimelineObjects()
	{
		List<Schema.SObjectType> gd = globalDescription.Values();	
		List<SelectOption> objects = new List<SelectOption>();
		List<SelectOption> tls = Timelines;

		for (Schema.SObjectType ot : gd)
		{
			if (objects.size() > 998) break;
			Schema.DescribeSObjectResult obj = ot.getDescribe();
			if (!obj.IsQueryable()) continue;
			String name = obj.getName();
			if (usedTimelines.contains(name)) continue;  // already used
			if (name.equalsIgnoreCase('Account') || name.equalsIgnoreCase('Contact')) continue;  // covered by the primary timeline
			String label = obj.getLabel();
			if (label.startsWith('Tag:') || label.startsWith('History:') || label.startsWith('Feed:') || label.startsWith('Share:')) continue;
			objects.add(new SelectOption(name, label + (label.replace(' ','').equalsIgnoreCase(name) ? '' : ' (' + name + ')')));
		}
		objects = selectOptionSortByLabel(objects);
		objects.add(0, new SelectOption('+', '- Choose a Timeline Object -'));
		return objects;
	}

	private Map<String, Schema.SObjectType> globalDescription
	{
		get
		{
			if (globalDescription == null)
			{
				globalDescription = Schema.getGlobalDescribe();
			}
			return globalDescription;
		}
		set;
	}


	static private List<SelectOption> fetchRecordTypes(Schema.sObjectType objType)
	{
		if (objType == null) return null;
		try
		{
			Schema.DescribeSObjectResult objDesc = objType.getDescribe();
			List<Schema.RecordTypeInfo> rectypes = objDesc.getRecordTypeInfos();
			List<SelectOption> rts = new List<SelectOption>();
			for (Schema.RecordTypeInfo rectype : rectypes)
			{
				rts.add(new SelectOption(rectype.getRecordTypeId(), rectype.getName()));
			}
			return rts;
		}
		catch (Exception e)
		{
		}
		return null;
	}

	public List<SelectOption> RecordTypeOptions
	{
		get
		{
			if (RecordTypeOptions == null)
			{
				if (eit == null || eit.ObjectType__c == null || eit.ObjectType__c == '') return null;
				try
				{
					Schema.sObjectType objType = globalDescription.get(eit.ObjectType__c.toLowerCase());
					if (objType == null) return null;
					RecordTypeOptions = fetchRecordTypes(objType);
				}
				catch (Exception e)
				{
					return null;		
				}
			}
			return RecordTypeOptions;
		}
		set;
	}
	public Boolean RecordTypeOptionsAvailable
	{
		get
		{
			if (RecordTypeOptions == null || RecordTypeOptions.size() < 1) return false;
			return true;
		}
	}
	public String[] recordTypes
	{
		get
		{
			if (recordTypes == null)
			{
				recordTypes = new String[]{};
			}
			return recordTypes;
		}
		set;
	}

	static private List<SelectOption> fetchRelationships(Schema.sObjectType objType, Schema.sObjectType parent)
	{
		if (objType == null || parent == null) return null;
		try
		{
			Schema.DescribeSObjectResult parDesc = parent.getDescribe(); 
			if (parDesc == null) return null;
			List<Schema.ChildRelationship> crs = parDesc.getChildRelationships();
			if (crs == null || crs.size() < 1) return null;
			List<SelectOption> rels = new List<SelectOption>();
			for (Schema.ChildRelationship cr : crs)
			{
				if (cr.getChildSObject() == objType)
				{
					rels.add(new SelectOption(cr.getRelationshipName(), cr.getRelationshipName()));
				}
			}
			return rels;
		}
		catch (Exception e)
		{
		}
		return null;
	}

	static private List<SelectOption> fetchFields(Schema.sObjectType objType, String[] fieldTypes, String[] referenceTypes, String path)
	{
		if (objType == null) return null;

		try
		{
			Schema.DescribeSObjectResult objDesc = objType.getDescribe(); 
			if (objDesc == null) return null;

			String rootname = objDesc.getLabel();
			String article = rootname.left(1).toUpperCase();
			if (article == 'A' || article == 'E' || article == 'I' || article == 'O' || article == 'U') article = 'an';
			else article = 'a';

			List<SelectOption> fields = new List<SelectOption>();
			String labelPrefix = rootname + ' > ';
			String fieldPrefix = '';

			if (path != null)
			{
				if (path == '.') path = '';
				if (path.length() > 0 && !path.endsWith('.')) path = path + '.';
				String objectPath = path;
				while (objectPath != '')
				{
					String objecttype;
					String fieldname = objectPath.substringBefore('.');
					objectPath = objectPath.substringAfter('.');
					if (fieldname == null || fieldname == '') continue;
					if (fieldname.contains('['))
					{
						objecttype = fieldname.substringAfter('[').substringBefore(']');
						fieldname = fieldname.substringBefore('[');
					}
					Schema.SObjectField field = objDesc.fields.getMap().get(fieldname);
					if (field == null) break;
					Schema.DescribeFieldResult fieldResult = field.getDescribe();
					List<Schema.sObjectType> references = fieldResult.getReferenceTo();
					if (references != null) for (Schema.sObjectType reference : references)
					{
						Schema.DescribeSObjectResult obj = reference.getDescribe();
						String objname = obj.getName();
						if (objecttype != null)  //  look for a match
						{
							if (obj.getName().equalsIgnoreCase(objecttype))
							{
								objDesc = obj;
								labelPrefix = labelPrefix + fieldResult.getLabel().replaceFirst(' [Ii][Dd]$', '') + ' (' + obj.getLabel() + ') > ';
								fieldPrefix = fieldPrefix + fieldResult.getRelationshipName() + '.';
								break;
							}
						}
						else  //  use the first one
						{
							objDesc = obj;
							labelPrefix = labelPrefix + fieldResult.getLabel().replaceFirst(' [Ii][Dd]$', '') + ' > ';
							fieldPrefix = fieldPrefix + fieldResult.getRelationshipName() + '.';
							break;
						}
					}
				}
			}
			else path = '';

			Map<String, Schema.SObjectField> mapFieldList = objDesc.fields.getMap();
			String objectname = objDesc.getName();

			List<SelectOption> parentFields = new List<SelectOption>();

			for (Schema.SObjectField field : mapFieldList.values())
			{
				Boolean found = false;					

				Schema.DescribeFieldResult fieldResult = field.getDescribe();
				if (fieldResult.isAccessible())
				{
					Schema.DisplayType fieldType = fieldResult.getType();
					String fieldTypeName = fieldType.name();
					String fieldName = fieldResult.getName();
					String fieldLabel = fieldResult.getLabel();
					if (fieldTypes != null)
					{
						for (String ft : fieldTypes)
						{
							if (fieldTypeName.equalsIgnoreCase(ft))
							{
								found = true;
								break;
							}
						}
					}
					if (fieldType == Schema.DisplayType.ID)
					{
						if (found == true && referenceTypes != null)
						{
							found = false;
							for (String rt : referenceTypes)
							{
								if (rt.equalsIgnoreCase(objectname))
								{
									found = true;
									break;
								}
							}
						}
					}
					if (fieldType == Schema.DisplayType.Reference)
					{
						List<String> refTypes = new List<String>();
						List<Schema.sObjectType> references = fieldResult.getReferenceTo();
						if (references != null) for (Schema.sObjectType reference : references)
						{
							Schema.DescribeSObjectResult refDesc = reference.getDescribe();
							refTypes.add(refDesc.getName());
							parentFields.add(new SelectOption(path + fieldName + (references.size() > 1 ? '[' + refDesc.getName() + ']' : '') + '.', labelPrefix + fieldLabel.replaceFirst(' [Ii][Dd]$', '') + (references.size() > 1 ? ' (' + refDesc.getLabel() + ')' : '') + ' > ...'));
						}
						if (found == true && referenceTypes != null)
						{
							found = false;
							for (String rt1 : refTypes)
							{
								if (found == false) for (String rt2 : referenceTypes)
								{
									if (rt1.equalsIgnoreCase(rt2))
									{
										found = true;
										break;
									}
								}
							}
						}
					}
					if (found)
						fields.add(new SelectOption(fieldPrefix + fieldName, labelPrefix + fieldLabel + (fieldName.equalsIgnoreCase('Id') || fieldLabel.replace(' ','').equalsIgnoreCase(fieldName) ? '' : ' (' + fieldName + ')')));
				}
			}
			fields = selectOptionSortByLabel(fields);
			parentFields = selectOptionSortByLabel(parentFields);
			if (parentFields.size() > 0)
			{
				fields.add(blankSelect());
				fields.addAll(parentFields);
			}
			if (path.length() > 0)
			{
				fields.add(0, blankSelect());
				String backpath = path.mid(0, path.length()-1);
				if (backpath.contains('.'))
				{
					backpath = backpath.substringBeforeLast('.') + '.';
					fields.add(0, new SelectOption('.', 'Go back to ' + rootname + ' fields...'));
				}
				else backpath = '.';
				String backlabel = labelPrefix.mid(0, labelPrefix.length() - 3);
				backlabel = backlabel.substringBeforeLast(' > ');
				fields.add(0, new SelectOption(backpath, 'Go back to ' + backlabel + ' fields...'));
				fields.add(0, blankSelect());
				fields.add(0, new SelectOption('', '- Choose ' + article + ' ' + labelPrefix.substringBeforeLast(' > ') + ' field -'));
			}
			else
			{
				fields.add(0, blankSelect());
				fields.add(0, new SelectOption('', '- Choose ' + article + ' ' + rootname + ' field -'));				
			}
			return fields;
		}
		catch (Exception e)
		{
			return null;
		}
		return null;
	}


	public List<SelectOption> fetchFields(String[] fieldTypes, String[] referenceTypes)
	{
		if (eit == null || eit.ObjectType__c == null || eit.ObjectType__c == '') return null;

		try
		{
			Schema.sObjectType objType = globalDescription.get(eit.ObjectType__c.toLowerCase());
			if (objType == null) return null;
			List<SelectOption> fields = fetchFields(objType, fieldTypes, referenceTypes, null);
			return fields;
		}
		catch (Exception e)
		{
			return null;
		}
		return null;
	}

	public List<SelectOption> fetchFields(String[] fieldTypes)
	{
		return fetchFields(fieldTypes, (String[])null);
	}

	private static String[] kInclusionFieldTypes = new String[] { 'ID', 'Reference', 'Boolean', 'String', 'TextArea', 'Combobox', 'Picklist', 'URL', 'Email', 'MultiPicklist', 'Date', 'DateTime', 'Integer', 'Double', 'Percent', 'Currency' };
	private static String[] kRecordIDFieldTypes = new String[] { 'ID', 'Reference' };
	private static String[] kParentContactIDFieldTypes = new String[] { 'ID', 'Reference' };
	private static String[] kParentContactIDFieldReferences = new String[]  { 'Contact' };
	private static String[] kParentAccountIDFieldTypes = new String[] { 'ID', 'Reference' };
	private static String[] kParentAccountIDFieldReferences = new String[]  { 'Account' };
	private static String[] kParentIDFieldTypes = new String[] { 'ID', 'Reference' };
	private static String[] kRecordNameFieldTypes = new String[] { 'String', 'TextArea', 'Combobox', 'Picklist' };
	private static String[] kHoverFieldTypes = new String[] { 'String', 'TextArea', 'Combobox', 'Picklist', 'Currency', 'Percent' };
	private static String[] kTertiaryFieldTypes = new String[] { 'String', 'TextArea', 'Combobox', 'Picklist', 'Currency', 'Percent' };
	private static String[] kDescriptionFieldTypes = new String[] { 'String', 'TextArea', 'Combobox', 'Picklist' };
	private static String[] kCustSatFieldTypes = new String[] { 'Integer', 'Double' };
	private static String[] kStartTimeFieldTypes = new String[] { 'Date', 'Datetime' };
	private static String[] kEndTimeFieldTypes = new String[] { 'Date', 'Datetime' };

	public Boolean subqueryRequired { get; set; }

	private String lastObjectType;

	public void UpdateAllFields()
	{
		if (RecordTypeOptions != null) RecordTypeOptions.clear();
		RecordTypeOptions = null;
		if (RecordIDFields != null) RecordIDFields.clear();
		RecordIDFields = null;
		if (InclusionFields != null) InclusionFields.clear();
		InclusionFields = null;
		if (ParentContactIDFields != null) ParentContactIDFields.clear();
		ParentContactIDFields = null;
		if (ParentAccountIDFields != null) ParentAccountIDFields.clear();
		ParentAccountIDFields = null;
		if (ParentIDFields != null) ParentIDFields.clear();
		ParentIDFields = null;
		if (RecordNameFields != null) RecordNameFields.clear();
		RecordNameFields = null;
		if (HoverFields != null) HoverFields.clear();
		HoverFields = null;
		if (DescriptionFields != null) DescriptionFields.clear();
		DescriptionFields = null;
		if (CustSatFields != null) CustSatFields.clear();
		CustSatFields = null;
		if (StartTimeFields != null) StartTimeFields.clear();
		StartTimeFields = null;
		if (EndTimeFields != null) EndTimeFields.clear();
		EndTimeFields = null;
		if (eit != null)
		{
			eit.RecordTypes2__c = null;
			eit.CustomTimelineObject__c = TimelineObject;
			eit.RecordIDField__c = 'Id';
			eit.InclusionField__c = null;
			eit.InclusionFieldPath__c = null;
			eit.ParentContactIDField__c = null;
			eit.ParentContactIDFieldPath__c = null;
			eit.ParentAccountIDField__c = null;
			eit.ParentAccountIDFieldPath__c = null;
			eit.AccountContactMatching__c = null;
			eit.RecordNameField__c = null;
			eit.RecordNameFieldPath__c = null;
			eit.HoverField__c = null;
			eit.HoverFieldPath__c = null;
			eit.DescriptionField__c = null;
			eit.DescriptionFieldPath__c = null;
			eit.CustSatField__c = null;
			eit.CustSatFieldPath__c = null;
			eit.StartTimeValue__c = null;
			eit.StartTimeValuePath__c = null;
			eit.EndTimeValue__c = null;
			eit.EndTimeValuePath__c = null;
			eit.RecordLimit__c = 50;
			subqueryRequired = null;
			if ( eit.ObjectType__c != null && eit.ObjectType__c != '')
			{
				if (eit.ObjectType__c != lastObjectType) eit.ExecuteAsSubquery__c = false;
				lastObjectType = eit.ObjectType__c;
				Schema.DescribeSObjectResult objdesc = globalDescription.get(eit.ObjectType__c.toLowerCase()).getDescribe();
				eit.Name = objdesc.getLabelPlural();
				//  Objects that cannot be queried directly include:
				//    - AccountContactRole
				//    - ActivityHistory
				//    - EmailStatus
				//    - Name
				//    - NotesAndAttachment
				//    - OpenActivity
				if (!objdesc.isQueryable())
				{
					eit.ExecuteAsSubquery__c = true;
					subqueryRequired = true;
				}
			}
		}
	}

	public List<SelectOption> RecordIDFields
	{
		get
		{
			if (RecordIDFields == null)
			{
				if (eit != null)
				{
					if (eit.RecordIDField__c != null && eit.RecordIDField__c.endsWith('.'))
						eit.RecordIDFieldPath__c = eit.RecordIDField__c;
					if (eit.RecordIDFieldPath__c != null && eit.RecordIDFieldPath__c.endsWith('.'))
						RecordIDFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kRecordIDFieldTypes, null, eit.RecordIDFieldPath__c);
					else RecordIDFields = fetchFields(kRecordIDFieldTypes, null);					
				}
				else RecordIDFields = fetchFields(kRecordIDFieldTypes, null);
			}
			return RecordIDFields;
		}
		set;		
	}
	public void UpdateRecordIDFields()
	{
		if (eit != null && eit.RecordIDField__c != null && (eit.RecordIDField__c.endsWith('.') || eit.RecordIDField__c == ''))
		{
			RecordIDFields.clear();
			RecordIDFields = null;
		}
	}

	public List<SelectOption> InclusionFields
	{
		get
		{
			if (InclusionFields == null)
			{
				if (eit != null)
				{
					if (eit.InclusionField__c != null && eit.InclusionField__c.endsWith('.'))
						eit.InclusionFieldPath__c = eit.InclusionField__c;
					if (eit.InclusionFieldPath__c != null && eit.InclusionFieldPath__c.endsWith('.'))
						InclusionFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kInclusionFieldTypes, null, eit.InclusionFieldPath__c);
					else InclusionFields = fetchFields(kInclusionFieldTypes);
				}
				else InclusionFields = fetchFields(kInclusionFieldTypes);
			}
			return InclusionFields;
		}
		set;
	}
	public void UpdateInclusionFields()
	{
		if (eit != null && eit.InclusionField__c != null && (eit.InclusionField__c.endsWith('.') || eit.InclusionField__c == ''))
		{
			InclusionFields.clear();
			InclusionFields = null;
		}
	}

	public List<SelectOption> ParentContactIDFields
	{
		get
		{
			if (ParentContactIDFields == null)
			{
				if (eit != null)
				{
					if (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c.endsWith('.'))
						eit.ParentContactIDFieldPath__c = eit.ParentContactIDField__c;
					if (eit.ParentContactIDFieldPath__c != null && eit.ParentContactIDFieldPath__c.endsWith('.'))
						ParentContactIDFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kParentContactIDFieldTypes, kParentContactIDFieldReferences, eit.ParentContactIDFieldPath__c);
					else ParentContactIDFields = fetchFields(kParentContactIDFieldTypes, kParentContactIDFieldReferences);
				}
				else ParentContactIDFields = fetchFields(kParentContactIDFieldTypes, kParentContactIDFieldReferences);
			}
			return ParentContactIDFields;
		}
		set;		
	}
	public void UpdateParentContactIDFields()
	{
		if (eit != null && eit.ParentContactIDField__c != null && (eit.ParentContactIDField__c.endsWith('.') || eit.ParentContactIDField__c == ''))
		{
			ParentContactIDFields.clear();
			ParentContactIDFields = null;
		}
	}
	public List<SelectOption> ContactRelationships
	{
		get
		{
			if (ContactRelationships == null)
			{
				if (eit != null && eit.ObjectType__c != null) ContactRelationships = fetchRelationships(globalDescription.get(eit.ObjectType__c.toLowerCase()), Contact.SObjectType);				
			}
			return ContactRelationships;
		}
		set;
	}

	public List<SelectOption> ParentAccountIDFields
	{
		get
		{
			if (ParentAccountIDFields == null)
			{
				if (eit != null)
				{
					if (eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c.endsWith('.'))
						eit.ParentAccountIDFieldPath__c = eit.ParentAccountIDField__c;
					if (eit.ParentAccountIDFieldPath__c != null && eit.ParentAccountIDFieldPath__c.endsWith('.'))
						ParentAccountIDFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kParentAccountIDFieldTypes, kParentAccountIDFieldReferences, eit.ParentAccountIDFieldPath__c);
					else ParentAccountIDFields = fetchFields(kParentAccountIDFieldTypes, kParentAccountIDFieldReferences);					
				}
				else ParentAccountIDFields = fetchFields(kParentAccountIDFieldTypes, kParentAccountIDFieldReferences);
			}
			return ParentAccountIDFields;
		}
		set;		
	}
	public void UpdateParentAccountIDFields()
	{
		if (eit != null && eit.ParentAccountIDField__c != null && (eit.ParentAccountIDField__c.endsWith('.') || eit.ParentAccountIDField__c == ''))
		{
			ParentAccountIDFields.clear();
			ParentAccountIDFields = null;
		}
	}
	public List<SelectOption> AccountRelationships
	{
		get
		{
			if (AccountRelationships == null)
			{
				if (eit != null && eit.ObjectType__c != null) AccountRelationships = fetchRelationships(globalDescription.get(eit.ObjectType__c.toLowerCase()), Account.SObjectType);				
			}
			return AccountRelationships;
		}
		set;
	}

	public List<SelectOption> ParentIDFields
	{
		get
		{
			if (ParentIDFields == null && TimelineObject != null && TimelineObject != '')
			{
				String[] parentRefs = new String[] { TimelineObject };
				if (eit != null)
				{
					if (eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c.endsWith('.'))
						eit.ParentAccountIDFieldPath__c = eit.ParentAccountIDField__c;
					if (eit.ParentAccountIDFieldPath__c != null && eit.ParentAccountIDFieldPath__c.endsWith('.'))
						ParentIDFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kParentIDFieldTypes, parentRefs, eit.ParentAccountIDFieldPath__c);
					else ParentIDFields = fetchFields(kParentIDFieldTypes, parentRefs);					
				}
				else ParentIDFields = fetchFields(kParentIDFieldTypes, parentRefs);
			}
			return ParentIDFields;
		}
		set;		
	}
	public void UpdateParentIDFields()
	{
		if (eit != null && eit.ParentAccountIDField__c != null && (eit.ParentAccountIDField__c.endsWith('.') || eit.ParentAccountIDField__c == ''))
		{
			ParentIDFields.clear();
			ParentIDFields = null;
		}
	}
	public List<SelectOption> ParentRelationships
	{
		get
		{
			if (ParentRelationships == null)
			{
				if (eit != null && eit.ObjectType__c != null && TimelineObject != null && TimelineObject != '')
					ParentRelationships = fetchRelationships(globalDescription.get(eit.ObjectType__c.toLowerCase()), globalDescription.get(TimelineObject.toLowerCase()));				
			}
			return ParentRelationships;
		}
		set;
	}

	public List<SelectOption> RecordNameFields
	{
		get
		{
			if (RecordNameFields == null)
			{
				if (eit != null)
				{
					if (eit.RecordNameField__c != null && eit.RecordNameField__c.endsWith('.'))
						eit.RecordNameFieldPath__c = eit.RecordNameField__c;
					if (eit.RecordNameFieldPath__c != null && eit.RecordNameFieldPath__c.endsWith('.'))
						RecordNameFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kRecordNameFieldTypes, null, eit.RecordNameFieldPath__c);
					else RecordNameFields = fetchFields(kRecordNameFieldTypes);
				}
				else RecordNameFields = fetchFields(kRecordNameFieldTypes);
			}
			return RecordNameFields;
		}
		set;
	}
	public void UpdateRecordNameFields()
	{
		if (eit != null && eit.RecordNameField__c != null && (eit.RecordNameField__c.endsWith('.') || eit.RecordNameField__c == ''))
		{
			RecordNameFields.clear();
			RecordNameFields = null;
		}
	}

	public List<SelectOption> HoverFields
	{
		get
		{
			if (HoverFields == null)
			{
				if (eit != null)
				{
					if (eit.HoverField__c != null && eit.HoverField__c.endsWith('.'))
						eit.HoverFieldPath__c = eit.HoverField__c;
					if (eit.HoverFieldPath__c != null && eit.HoverFieldPath__c.endsWith('.'))
						HoverFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kHoverFieldTypes, null, eit.HoverFieldPath__c);
					else HoverFields = fetchFields(kHoverFieldTypes);
				}
				else HoverFields = fetchFields(kHoverFieldTypes);
			}
			return HoverFields;
		}
		set;
	}
	public void UpdateHoverFields()
	{
		if (eit != null && eit.HoverField__c != null && (eit.HoverField__c.endsWith('.') || eit.HoverField__c == ''))
		{
			HoverFields.clear();
			HoverFields = null;
		}
	}

	public List<SelectOption> DescriptionFields
	{
		get
		{
			if (DescriptionFields == null)
			{
				if (eit != null)
				{
					if (eit.DescriptionField__c != null && eit.DescriptionField__c.endsWith('.'))
						eit.DescriptionFieldPath__c = eit.DescriptionField__c;
					if (eit.DescriptionFieldPath__c != null && eit.DescriptionFieldPath__c.endsWith('.'))
						DescriptionFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kDescriptionFieldTypes, null, eit.DescriptionFieldPath__c);
					else DescriptionFields = fetchFields(kDescriptionFieldTypes);
				}
				else DescriptionFields = fetchFields(kDescriptionFieldTypes);
			}
			return DescriptionFields;
		}
		set;
	}
	public void UpdateDescriptionFields()
	{
		if (eit != null && eit.DescriptionField__c != null && (eit.DescriptionField__c.endsWith('.') || eit.DescriptionField__c == ''))
		{
			DescriptionFields.clear();
			DescriptionFields = null;
		}
	}

	public List<SelectOption> CustSatFields
	{
		get
		{
			if (CustSatFields == null)
			{
				if (eit != null)
				{
					if (eit.CustSatField__c != null && eit.CustSatField__c.endsWith('.'))
						eit.CustSatFieldPath__c = eit.CustSatField__c;
					if (eit.CustSatFieldPath__c != null && eit.CustSatFieldPath__c.endsWith('.'))
						CustSatFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kCustSatFieldTypes, null, eit.CustSatFieldPath__c);
					else CustSatFields = fetchFields(kCustSatFieldTypes);
				}
				else CustSatFields = fetchFields(kCustSatFieldTypes);
			}
			return CustSatFields;
		}
		set;
	}
	public void UpdateCustSatFields()
	{
		if (eit != null && eit.CustSatField__c != null && (eit.CustSatField__c.endsWith('.') || eit.CustSatField__c == ''))
		{
			CustSatFields.clear();
			CustSatFields = null;
			eit.CustSatOnly__c = false;
		}
	}

	public List<SelectOption> StartTimeFields
	{
		get
		{
			if (StartTimeFields == null)
			{
				if (eit != null)
				{
					if (eit.StartTimeValue__c != null && eit.StartTimeValue__c.endsWith('.'))
						eit.StartTimeValuePath__c = eit.StartTimeValue__c;
					if (eit.StartTimeValuePath__c != null && eit.StartTimeValuePath__c.endsWith('.'))
						StartTimeFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kStartTimeFieldTypes, null, eit.StartTimeValuePath__c);
					else StartTimeFields = fetchFields(kStartTimeFieldTypes);
				}
				else StartTimeFields = fetchFields(kStartTimeFieldTypes);
			}
			return StartTimeFields;
		}
		set;		
	}
	public void UpdateStartTimeFields()
	{
		if (eit != null && eit.StartTimeValue__c != null && (eit.StartTimeValue__c.endsWith('.') || eit.StartTimeValue__c == ''))
		{
			StartTimeFields.clear();
			StartTimeFields = null;
		}
	}

	public List<SelectOption> EndTimeFields
	{
		get
		{
			if (EndTimeFields == null)
			{
				if (eit != null)
				{
					if (eit.EndTimeValue__c != null && eit.EndTimeValue__c.endsWith('.'))
						eit.EndTimeValuePath__c = eit.EndTimeValue__c;
					if (eit.EndTimeValuePath__c != null && eit.EndTimeValuePath__c.endsWith('.'))
						EndTimeFields = fetchFields(globalDescription.get(eit.ObjectType__c.toLowerCase()), kEndTimeFieldTypes, null, eit.EndTimeValuePath__c);
					else EndTimeFields = fetchFields(kEndTimeFieldTypes);
				}
				else EndTimeFields = fetchFields(kEndTimeFieldTypes);
			}
			return EndTimeFields;
		}
		set;		
	}
	public void UpdateEndTimeFields()
	{
		if (eit != null && eit.EndTimeValue__c != null && (eit.EndTimeValue__c.endsWith('.') || eit.EndTimeValue__c == ''))
		{
			EndTimeFields.clear();
			EndTimeFields = null;
		}
	}

	public Integer order
	{
		get
		{
			if (order == null)
			{
				String ord = ApexPages.currentPage().getParameters().get('order');
				if (ord != null && ord != '' && ord.isNumeric()) order = Integer.valueOf(ord);
				else return null;
			}
			return order;
		}
		set;
	}

	public PageReference reorder()
	{
		if (eitID == null || eit == null) return null;
		if (order == null || order < 1) return null;
		if (!EIT__c.SObjectType.getDescribe().isUpdateable() || !EIT__c.fields.Order__c.getDescribe().isUpdateable())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient privileges to reorder Timeline Event'));
			return null;
		}
		if (TimelineObject == '') TimelineObject = null;
		Integer newOrder = order;
		Integer oldOrder = (Integer)eit.Order__c;
		if (newOrder == oldOrder) return null;
		Integer minOrder = Math.min(newOrder, oldOrder);
		Integer maxOrder = Math.max(newOrder, oldOrder);
		Integer increment = (newOrder > oldOrder ? -1 : 1);
		eit.Order__c = newOrder;
		List<EIT__c> ts = [SELECT Id, Order__c FROM EIT__c WHERE CustomTimelineObject__c = :TimelineObject AND Order__c >= :minOrder AND Order__c <= :maxOrder AND Id != :eit.Id];
		if (ts == null) ts = new List<EIT__c>();
		for (EIT__c t : ts)
		{
			t.Order__c += increment;
		}
		ts.add(eit);
		update ts;
		ts.clear();
		eitwrappers.clear();
		eitwrappers = null;
		eit = null;
		eits.clear();
		eits = null;
		eitID = null;
		return null;
	}

	public String categoryName { get; set; }
	public PageReference addCategory()
	{
		if (categoryName == null || categoryName == '') return null;
		if (!Category__c.SObjectType.getDescribe().isCreateable() || !Category__c.fields.Name.getDescribe().isUpdateable())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient privileges to create Timeline Category'));
			return null;
		}
		if (TimelineObject == '') TimelineObject = null;
		Category__c cat = new Category__c();
		cat.Name = categoryName;
		cat.CustomTimelineObject__c = TimelineObject;
		insert cat;
		categoryName = null;
		EIT_Categories.clear();
		EIT_Categories = null;
		return null;
	}

	public Boolean showNewCat { get { if (showNewCat == null) showNewCat = false; return showNewCat; } set; }
	public PageReference toggleNewCat()
	{
		showNewCat = !showNewCat;
		return null;
	}
	
	public String catID { get; set; }
	public PageReference toggleCategoryVisibility()
	{
		if (catID == null || catID == '') return null;
		if (!Category__c.SObjectType.getDescribe().isUpdateable() ||
			!Category__c.fields.DefaultVisibility__c.getDescribe().isUpdateable())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient privileges to update Timeline Category'));
			return null;
		}
		if (TimelineObject == '') TimelineObject = null;
		List<Category__c> cats = [SELECT Id, Name, DefaultVisibility__c FROM Category__c WHERE Id = :catID LIMIT 1];
		if (cats != null && cats.size() > 0)
		{
			cats[0].DefaultVisibility__c = !cats[0].DefaultVisibility__c;
			update cats[0];
		}
		EIT_Categories.clear();
		EIT_Categories = null;
		return null;
	}


	public PageReference remove()
	{
		if (eitID == null || eit == null) return null;
		if (!EIT__c.SObjectType.getDescribe().isUpdateable() || !EIT__c.SObjectType.getDescribe().isDeletable()
			|| !EIT__c.fields.Order__c.getDescribe().isUpdateable())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient privileges to delete Timeline Event'));
			return null;
		}
		if (TimelineObject == '') TimelineObject = null;
		if (eit.Order__c != null)
		{
			Integer oldOrder = (Integer)eit.Order__c;
			List<EIT__c> ts = [SELECT Id, Order__c FROM EIT__c WHERE CustomTimelineObject__c = :TimelineObject AND Order__c > :oldOrder AND Id != :eit.Id];
			if (ts == null) ts = new List<EIT__c>();
			for (EIT__c t : ts)
			{
				t.Order__c -= 1;
			}
			update ts;
			ts.clear();
		}
		delete eit;
		eitwrappers.clear();
		eitwrappers = null;
		eitcount = null;
		eit = null;
		eits.clear();
		eits = null;
		eitID = null;
		return null;
	}

	public PageReference save()
	{
		if (!EIT__c.SObjectType.getDescribe().isUpdateable() || !EIT__c.SObjectType.getDescribe().isCreateable()
			|| !EIT__c.fields.Order__c.getDescribe().isUpdateable())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient privileges to save Timeline Event'));
			return null;
		}
		try
		{
			if (TimelineObject == '') TimelineObject = null;
			if (eit.RecordLimit__c == null || eit.RecordLimit__c < 1) eit.RecordLimit__c = 50;

			eit.RecordTypes2__c = null;
			if (RecordTypes != null && RecordTypes.size() > 0)
			{
				eit.RecordTypes2__c = '';
				for (String s : RecordTypes) eit.RecordTypes2__c += s + ';';
			}
			if (eit.InclusionFieldPath__c == '.') eit.InclusionFieldPath__c = null;
			if (eit.ParentContactIDFieldPath__c == '.') eit.ParentContactIDFieldPath__c = null;
			if (eit.ParentAccountIDFieldPath__c == '.') eit.ParentAccountIDFieldPath__c = null;
			if (eit.RecordNameFieldPath__c == '.') eit.RecordNameFieldPath__c = null;
			if (eit.HoverFieldPath__c == '.') eit.HoverFieldPath__c = null;
			if (eit.DescriptionFieldPath__c == '.') eit.DescriptionFieldPath__c = null;
			if (eit.CustSatFieldPath__c == '.') eit.CustSatFieldPath__c = null;
			if (eit.StartTimeValuePath__c == '.') eit.StartTimeValuePath__c = null;
			if (eit.EndTimeValuePath__c == '.') eit.EndTimeValuePath__c = null;

			if (eit.ParentContactIDField__c == null || eit.ParentContactIDField__c == '' || eit.ParentAccountIDField__c == null || eit.ParentAccountIDField__c == '')
				eit.AccountContactMatching__c = null;
			else if (eit.ParentContactIDField__c == eit.ParentAccountIDField__c)
				eit.AccountContactMatching__c = 'CTX';
			else if (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '')
				if (eit.AccountContactMatching__c == null || eit.AccountContactMatching__c == '') eit.AccountContactMatching__c = 'CTX';

			if (eit.RecordIDField__c == null || eit.RecordIDField__c == '') eit.RecordIDField__c = 'Id';
			if (eit.CustSatField__c != null && eit.CustSatField__c != '' && eit.CustSatWeighting__c == null)
				eit.CustSatWeighting__c = 1.0;

			if (eit.Order__c == null)
			{
				//  add to bottom of order
				List<EIT__c> lasteit = [SELECT Id, Order__c FROM EIT__c WHERE CustomTimelineObject__c = :TimelineObject ORDER BY Order__c DESC LIMIT 1];
				if (lasteit != null && lasteit.size() > 0 && lasteit[0].Order__c != null) eit.Order__c = lasteit[0].Order__c + 1;
				else eit.Order__c = 1;
			}
			if (eit.Id == null)
			{
				List<EIT__c> eits = [SELECT Id, Order__c FROM EIT__c WHERE CustomTimelineObject__c = :TimelineObject AND Order__c >= :eit.Order__c];
				{
					if (eits != null & eits.size() > 0)
					{
						for (EIT__c t : eits)
						{
							t.Order__c += 1;
						}
						update eits;
					}
				}
				insert eit;
			}
			else
			{
				upsert eit;
			}
			PageReference pr;
			String retURL = ApexPages.currentPage().getParameters().get('retURL'); 
			if (retURL != null && retURL != '')
			{
				pr = new PageReference(retURL);
				pr.setRedirect(true);
				return pr;
			}
			pr = new PageReference('/' + eit.Id);
			pr.setRedirect(true);
			return pr;
		}
		catch (Exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save Timeline Event'));
			ApexPages.addMessages(e);
			return null;
		}
		return null;
	}

	public PageReference setupSamples()
	{
		Install eiti = new Install();
		if (categorycount == 0 && eitcount == 0) eiti.onInstall(null);
		PageReference ref = new PageReference(Page.List.getUrl());
		ref.setRedirect(true);
		return ref;
	}

	public PageReference openTimeline()
	{
		eitcount = null;
		eit.clear();
		eits.clear();
		eits = null;
		eit = null;
		eitwrappers.clear();
		eitwrappers = null;
		EIT_Categories.clear();
		EIT_Categories = null;
		Timelines.clear();
		Timelines = null;
		usedTimelines.clear();
		showNewCat = false;
		return null;
	}

}