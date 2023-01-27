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



global without sharing class Timeline
{

	public class CustID
	{
		public Id ID { get; set; }
		public String ObjectType;
		public Id AccountID;
		public Id ContactID;
		public Boolean IsPersonAccount = false;
		public Boolean IsPrimary = false;
		public Boolean IsContextual = false;
		private Timeline Timeline;

		public CustID(Id id, Timeline tl)
		{
			if (id == null) return;
			if (tl == null) return;
			this.Timeline = tl;
			this.ID = id;
			ObjectType = id.getSObjectType().getDescribe().getName();
			if (((String)id).startsWith('001'))
			{
				this.AccountID = id;
				if (personAccountsEnabled)
				{
					String query = 'SELECT IsPersonAccount, PersonContactId FROM Account WHERE Id = \'' + id + '\'';
					List<Account> pas = Database.query(query);
					if (pas != null && pas.size() > 0)
					{
						IsPersonAccount = (Boolean)pas[0].get('IsPersonAccount');
						if (IsPersonAccount)
						{
							this.ContactID = (Id)pas[0].get('PersonContactId');
							if (Timeline.AccountID == null) Timeline.AccountID = this;
							else Timeline.ContactID = this;
						}
						else if (Timeline.AccountID == null) Timeline.AccountID = this;
						else if (Timeline.AccountID.IsPersonAccount && Timeline.ContactID == null)
						{
							Timeline.ContactID = Timeline.AccountID;
							Timeline.AccountID = this;
						}
					}
				}
				else if (Timeline.AccountID == null) Timeline.AccountID = this;
			}
			else if (((String)id).startsWith('003'))
			{
				this.ContactID = id;
				if (personAccountsEnabled)
				{
					String query = 'SELECT IsPersonAccount, AccountId FROM Contact WHERE Id = \'' + id + '\'';
					List<Contact> pas = Database.query(query);
					if (pas != null && pas.size() > 0)
					{
						IsPersonAccount = (Boolean)pas[0].get('IsPersonAccount');
						if (IsPersonAccount)
						{
							this.AccountID = pas[0].AccountId;
							if (Timeline.AccountID == null) Timeline.AccountID = this;
							else Timeline.ContactID = this;
						}
						else Timeline.ContactID = this;
					}
				}
				else Timeline.ContactID = this;
			}
		}
	}


	public Id ComponentID { get; set; }
	public Id AlternateID { get; set; }

	public CustID PrimaryID
	{
		get
		{
			if (PrimaryID == null)
			{
				if (ComponentID != null) PrimaryID = new CustID(ComponentID, this);
				else
				{
					String pid = ApexPages.currentPage().getParameters().get('id');
					if (pid != null && pid != '') PrimaryID = new CustID(Id.valueOf(pid), this);
				}
				if (PrimaryID != null) PrimaryID.IsPrimary = true;
				if (PrimaryID != null && PrimaryID.IsPersonAccount)
				{
					if (PrimaryID.ID == PrimaryID.ContactID) AlternateID = PrimaryID.AccountID;
					else if (PrimaryID.ID == PrimaryID.AccountID) AlternateID = PrimaryID.ContactID;
				}
			}
			return PrimaryID;
		}
		set;
	}


	public CustID ContextID
	{
		get
		{
			if (ContextID == null)
			{
				String xid = ApexPages.currentPage().getParameters().get('xid');
				if (xid == null || xid == '') xid = ApexPages.currentPage().getParameters().get('aid');
				if (xid == null || xid == '') xid = ApexPages.currentPage().getParameters().get('cid');
				if (xid != null && xid != '') ContextID = new CustID(Id.valueOf(xid), this);
			}
			if (ContextID != null) ContextID.IsContextual = true;
			return ContextID;
		}
		set;
	}

	public CustID ContactID { get; set; }
	public CustID AccountID { get; set; }


	public Timeline_Display__c Settings
	{
		get
		{
			if (Settings == null)
			{
				Settings = Timeline_Display__c.getInstance();
				if (Settings == null) Settings = new Timeline_Display__c();
				// set up default behaviors
				if (Settings.get('Scrolling__c') == null) Settings.Scrolling__c = false;
				if (Settings.get('Zoom_Center__c') == null) Settings.Zoom_Center__c = false;
				if (Settings.get('Auto_Center_Recent__c') == null) Settings.Auto_Center_Recent__c = false;
				if (Settings.get('Default_Zoom__c') == null) Settings.Default_Zoom__c = 7;
				if (Settings.Target__c == null || Settings.Target__c == '') Settings.Target__c = 'subtab';
			}
			return Settings;
		}
		set;
	}

	//  Test to see if person accounts are enabled.
	public static Boolean personAccountsEnabled
	{
		get
		{
			if ( personAccountsEnabled == null )
			{
				try
				{
					//  Try to use the isPersonAccount field.
					SObject testObject = new Account();
					testObject.get('IsPersonAccount');
					//  If we got here without an exception, return true.
					personAccountsEnabled = true;
				}
				catch(Exception ex)
				{
					//  An exception was generated trying to access the isPersonAccount field
					//  so person accounts aren't enabled; return false.
					personAccountsEnabled = false;
				}
			}
			return personAccountsEnabled;
		}
		set;
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

	public List<EIT__c> eits
	{
		get
		{
			if (eits == null)
			{
				String TimelineObject = null;
				if (PrimaryID != null && PrimaryID.ObjectType != null)
				{
					if (PrimaryID.ObjectType.equalsIgnoreCase('Account') || PrimaryID.ObjectType.equalsIgnoreCase('Contact'))
						TimelineObject = null;
					else TimelineObject = PrimaryID.ObjectType;
				}
				eits =
				[
					SELECT
						Id,
						Name,
						Active__c,
						Order__c,
						ObjectType__c,
						ExecuteAsSubquery__c,
						RecordTypes2__c,
						RecordIDField__c,
						InclusionField__c,
						InclusionFieldPath__c,
						ParentContactIDField__c,
						ParentAccountIDField__c,
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
						Active__c = true
							AND
						CustomTimelineObject__c = :TimelineObject
					ORDER BY
						Order__c ASC
				];
			}
			return eits;
		}
		set;
	}

	public List<Category__c> EIT_Categories
	{
		get
		{
			if (EIT_Categories == null)
			{
				String TimelineObject = null;
				if (PrimaryID != null && PrimaryID.ObjectType != null)
				{
					if (PrimaryID.ObjectType.equalsIgnoreCase('Account') || PrimaryID.ObjectType.equalsIgnoreCase('Contact'))
						TimelineObject = null;
					else TimelineObject = PrimaryID.ObjectType;
				}
				EIT_Categories =
				[
					SELECT
						Id,
						Name,
						DefaultVisibility__c
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

	static public SObject getObject(SObject obj, String field)
	{
		if (obj == null || field == null || field == '') return obj;
		if (field.contains('.'))
		{
			return getObject(obj.getSObject(field.substringBefore('.')), field.substringAfter('.'));
		}
		else return obj;
	}

	static public Object getValue(SObject obj, String field)
	{
		if (obj == null || field == null || field == '') return null;
		if (field.substring(0,1) == '"')
		{
			Integer len = field.length();
			if (field.substring(len-1,len) == '"') return field.substring(1,len-1);
			else return field.substring(1); 
		}
		if (field.contains('.'))
		{
			return getValue(obj.getSObject(field.substringBefore('.')), field.substringAfter('.'));
		}
		else return obj.get(field);
	}

	public class event
	{
		//  class used to populate the SIMILE Timeline widget in JSON format

		public Datetime start { get; set; }                //  event beginning time
		public Datetime latestStart { get; set; }          //  imprecise beginning
		public Datetime earliestEnd { get; set; }          //  imprecise end
		public Datetime end_reservedKeyword { get; set; }  //  event end time
		public Boolean durationEvent { get; set; }         //  whether "duration" tape (no icon) or "instant" (icon)  
		public String title { get; set; }                  //  short event name in timeline, next to tape or icon
		public String icon { get; set; }                   //  URL to image to appear next to title text if (no end date) or (durationEvent = false)
		public String image { get; set; }                  //  URL to an image that will be displayed in the bubble
		public String link { get; set; }                   //  bubble's title text be a hyper-link to this URL
		public String color { get; set; }                  //  color of text and tape in timeline; if event has durationEvent = false, tape opacity will be applied (default 20%)
		public String textColor { get; set; }              //  color of label text on timeline; if not set, color attribute will be used
		public String tapeImage { get; set; }              //  background image for event's tape on timeline; overrides color setting
		public String tapeRepeat { get; set; }             //  tapeImage repeat style: one of {repeat | repeat-x | repeat-y} (default is "repeat")
		public String caption { get; set; }                //  additional event information shown in hover (HTML "title" attribute), like tooltip; plain text only
		public String classname { get; set; }              //  added to HTML classnames for event's label and tape DIVs ('hot_event' will result in DIV classes of 'timeline-event-label hot_event' and 'timeline-event-tape hot_event')
		public String description { get; set; }            //  displayed inside bubble with event's title and image
		public Double custSat { get; set; }                //  normalized customer satisfaction rating for this event (-1.0 to +1.0, with 0.0 being neutral)
		private Id eit;
	}

	private Map<Id, event> eventMap
	{
		get
		{
			if (eventMap == null)
				eventMap = new Map<Id, event>();
			return eventMap;
		}
		set;
	}

	public Integer TimelineHeight { get; set; }
	public Boolean IncludeCSATMeter { get; set; }
	private Boolean csatonly
	{
		get
		{
			if (csatonly == null)
			{
				String csatonlyparm = ApexPages.currentPage().getParameters().get('csatonly');
				csatonly = (csatonlyparm == null || csatonlyparm == '' || csatonlyparm == 'n' || csatonlyparm == 'N' || csatonlyparm == '0') ? false : true;
			}
			return csatonly;
		}
		set;
	}
	
	public class TimelineEvents
	{
		public String dateTimeFormat
		{
			get
			{
				if (dateTimeFormat == null) dateTimeFormat = 'iso8601';
				return dateTimeFormat;
			}
			set;
		}
		public List<event> events { get; set; }
		public Double customerSatScore { get; set; }
		public DateTime lastPastEvent { get; set; }
		public DateTime lastEvent { get; set; }
	}

	private Boolean isFieldAccessible(Schema.DescribeSObjectResult objdesc, String fieldSelect, String path)
	{
		if (objdesc == null) return false;
		if (fieldSelect == null || fieldSelect == '') return true;  //  no field actually requested
		if (getFieldType(objdesc, fieldSelect, path) == null) return false;
		return true;
	}

	private Schema.DisplayType getFieldType(Schema.DescribeSObjectResult objdesc, String fieldSelect, String path)
	{
		if (objdesc == null || fieldSelect == null || fieldSelect == '') return null;
		if (!objdesc.isAccessible()) return null;

		Schema.SObjectField theField;

		try
		{
			if (fieldSelect.substring(0,1) == '"') return Schema.DisplayType.String;
			if (path != null && path != '')
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
					Schema.SObjectField field = objdesc.fields.getMap().get(fieldname.toLowerCase());
					if (field == null) break;
					Schema.DescribeFieldResult fieldResult = field.getDescribe();
					if (!fieldResult.isAccessible()) return null;
					List<Schema.SObjectType> references = fieldResult.getReferenceTo();
					if (references != null) for (Schema.SObjectType reference : references)
					{
						Schema.DescribeSObjectResult obj = reference.getDescribe();
						String objname = obj.getName();
						if (objecttype != null)  //  look for a match
						{
							if (objname.equalsIgnoreCase(objecttype))
							{
								objdesc = obj;
								break;
							}
						}
						else  //  use the first one
						{
							objdesc = obj;
							break;
						}
					}
				}
			}
		}
		catch (Exception e)
		{
			return null;
		}
		if (objdesc == null) return null;
		String individualFieldName = fieldSelect.contains('.') ? fieldSelect.substringAfter('.') : fieldSelect;

		Schema.SObjectField iftoken = objdesc.fields.getMap().get(individualFieldName.toLowerCase());
		if (iftoken != null)
		{
			Schema.DescribeFieldResult fieldResult = iftoken.getDescribe();
			if (!fieldResult.isAccessible()) return null;
			return fieldResult.getType();
		}
		else
			return null;
	}


	public TimelineEvents timeline
	{
		get
		{
			if (timeline == null)
			{
				timeline = new TimelineEvents();
				timeline.events = new List<event>();

				if (eits != null)
				{
					String TimelineObject = null;
					String urlPrefix = Site.getPathPrefix();
					if (urlPrefix == null) urlPrefix = '';
					if (PrimaryID != null && PrimaryID.ObjectType != null)
					{
						if (PrimaryID.ObjectType.equalsIgnoreCase('Account') || PrimaryID.ObjectType.equalsIgnoreCase('Contact'))
							TimelineObject = null;
						else TimelineObject = PrimaryID.ObjectType;
					}
					List<SObject> objs = new List<SObject>();
					Double totalsat = 0.0;
					Double totalsatcount = 0;
					DateTime now = DateTime.now();
					Time midnight = Time.newInstance(0, 0, 0, 0);
					List<Messaging.SingleEmailMessage> errorNotifications = new List<Messaging.SingleEmailMessage>();
					for (EIT__c eit : eits)
					{
						//
						//  TO DO : also handle when ParentContactID and ParentAccountID are the same field: always use "OR" logic
						//
						try
						{
							Schema.SObjectType objType = globalDescription.get(eit.ObjectType__c.toLowerCase());
							Schema.DescribeSObjectResult objDesc = objType.getDescribe();

							//  do not run queries for inaccessible objects: enforce FLS and CRUD model
							if (!objDesc.isAccessible()) continue;
							if (!isFieldAccessible(objDesc, eit.RecordNameField__c, eit.RecordNameFieldPath__c)) continue;
							if (!isFieldAccessible(objDesc, eit.DescriptionField__c, eit.DescriptionFieldPath__c)) continue;
							if (!isFieldAccessible(objDesc, eit.CustSatField__c, eit.CustSatFieldPath__c)) continue;
							Schema.DisplayType inclusionFieldType = null;
							Schema.DisplayType hoverFieldType = null;
							Schema.DisplayType startTimeType = null;
							Schema.DisplayType endTimeType = null;
							Integer RecordLimit = 50;
							if (eit.RecordLimit__c != null && eit.RecordLimit__c > 0)
								RecordLimit = (Integer)eit.RecordLimit__c;
							String dateQuery = null;
							if (eit.StartTimeValue__c != null && eit.StartTimeValue__c != '')
							{
								startTimeType = getFieldType(objDesc, eit.StartTimeValue__c, eit.StartTimeValuePath__c);
								if (startTimeType == null) continue;  //  field not accessible by current user
								dateQuery = eit.StartTimeValue__c + ' != null';
							}
							if (eit.EndTimeValue__c != null && eit.EndTimeValue__c != '')
							{
								endTimeType = getFieldType(objDesc, eit.EndTimeValue__c, eit.EndTimeValuePath__c);
								if (endTimeType == null) continue;  //  field not accessible by current user
								if (dateQuery == null)
									dateQuery = eit.EndTimeValue__c + ' != null';
								else
									dateQuery = '(' + dateQuery + ' OR ' + eit.EndTimeValue__c + ' != null)';
							}



							String inclusionQuery = null;
							if (eit.InclusionField__c != null && eit.InclusionField__c != '')
							{
								inclusionFieldType = getFieldType(objDesc, eit.InclusionField__c, eit.InclusionFieldPath__c);
								if (inclusionFieldType == null) continue;  //  field not accessible by current user
								if (inclusionFieldType == Schema.DisplayType.String || inclusionFieldType == Schema.DisplayType.TextArea || inclusionFieldType == Schema.DisplayType.Combobox || inclusionFieldType == Schema.DisplayType.Picklist || inclusionFieldType == Schema.DisplayType.Email || inclusionFieldType == Schema.DisplayType.URL || inclusionFieldType == Schema.DisplayType.MultiPicklist)
									inclusionQuery = eit.InclusionField__c + ' != null AND ' + eit.InclusionField__c + ' NOT IN (\'\', \'0\', \';\', \'NO\', \'no\', \'No\', \'FALSE\', \'false\', \'False\')';
								else if (inclusionFieldType == Schema.DisplayType.Integer || inclusionFieldType == Schema.DisplayType.Double || inclusionFieldType == Schema.DisplayType.Currency || inclusionFieldType == Schema.DisplayType.Percent)
									inclusionQuery = eit.InclusionField__c + ' != null AND ' + eit.InclusionField__c + ' != 0';
								else if (inclusionFieldType == Schema.DisplayType.Boolean)
									inclusionQuery = eit.InclusionField__c + ' = true';
								else
									inclusionQuery = eit.InclusionField__c + ' != null';
							}
							if (eit.HoverField__c != null && eit.HoverField__c != '')
							{
								hoverFieldType = getFieldType(objDesc, eit.HoverField__c, eit.HoverFieldPath__c);
								if (hoverFieldType == null) continue;  //  field not accessible by current user
							}

							String recordIDField = eit.RecordIDField__c;
							if (recordIDField == null || recordIDField == '') recordIDField = 'Id';
							String objLabel = '';
							String query;
							if (recordIDField.equalsIgnoreCase('Id'))
							{
								query = queryAddFields('SELECT ', new String[] {recordIDField, eit.RecordNameField__c, eit.HoverField__c, eit.DescriptionField__c, eit.CustSatField__c, eit.InclusionField__c, eit.StartTimeValue__c, eit.EndTimeValue__c});
								objLabel = objdesc.getLabel();
							}
							else
							{
								query = queryAddFields('SELECT ', new String[] {recordIDField, eit.RecordNameField__c, eit.HoverField__c, eit.DescriptionField__c, eit.CustSatField__c, eit.InclusionField__c, eit.StartTimeValue__c, eit.EndTimeValue__c, 'Id'});
							}
							if (objLabel == null) objLabel = '';
							else if (objLabel != '') objLabel += ' ';



							//  custom icon section
							if (eit.Icon__c != null && eit.Icon__c.right(3) == '__c')
							{
								Schema.DisplayType fieldType = getFieldType(objDesc, eit.Icon__c, null);
								if (fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Picklist
								    || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.URL)
									query += ', ' + eit.Icon__c;
								else continue;  // no access
							}
							if (eit.Image__c != null && eit.Image__c.right(3) == '__c')
							{
								Schema.DisplayType fieldType = getFieldType(objDesc, eit.Image__c, null);
								if (fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Picklist
								    || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.URL)
									query += ', ' + eit.Image__c;
								else continue;  // no access
							}
							if (eit.Color__c != null && eit.Color__c.right(3) == '__c')
							{
								Schema.DisplayType fieldType = getFieldType(objDesc, eit.Color__c, null);
								if (fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Picklist
								    || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.URL)
									query += ', ' + eit.Color__c;
								else continue;  // no access
							}
							if (eit.TextColor__c != null && eit.TextColor__c.right(3) == '__c')
							{
								Schema.DisplayType fieldType = getFieldType(objDesc, eit.TextColor__c, null);
								if (fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Picklist
								    || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.URL)
									query += ', ' + eit.TextColor__c;
								else continue;  // no access
							}
							if (eit.TapeImage__c != null && eit.TapeImage__c.right(3) == '__c')
							{
								Schema.DisplayType fieldType = getFieldType(objDesc, eit.TapeImage__c, null);
								if (fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Picklist
								    || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.URL)
									query += ', ' + eit.TapeImage__c;
								else continue;  // no access
							}

							String recordTypes = null;
							if (eit.RecordTypes2__c != null && eit.RecordTypes2__c.length() > 1)
							{
								for (String rt : eit.RecordTypes2__c.split(';'))
									if (rt != null && rt.length() > 1) recordTypes = (recordTypes == null ? 'RecordTypeId IN (\'' : recordTypes + '\', \'') + rt;
								if (recordTypes != null) recordTypes += '\')';
							}
							String selectorQuery = null;
							if (recordTypes != null) selectorQuery = recordTypes;
							if (dateQuery != null) selectorQuery = (selectorQuery == null ? dateQuery : selectorQuery + ' AND ' + dateQuery);
							if (inclusionQuery != null) selectorQuery = (selectorQuery == null ? inclusionQuery : selectorQuery + ' AND ' + inclusionQuery);

							//
							//  customer disposition calculation
							//
							Double range;
							Double offset;
							Double eitsat = 0.0;
							Double eitsatcount = 0;
							Double nowday = (Double)System.currentTimeMillis() / 86400000.0;
							if (eit.CustSatField__c != null && eit.CustSatField__c != '' && eit.CustSatWorst__c != null && eit.CustSatBest__c != null && eit.CustSatWorst__c != eit.CustSatBest__c)
							{
								range = eit.CustSatBest__c - eit.CustSatWorst__c;
								offset = (eit.CustSatWorst__c + eit.CustSatBest__c) / 2.0;
							}

							if (TimelineObject == null)
							{
								//
								//  standard customer (Account/Contact) timeline
								//
								if (eit.ExecuteAsSubquery__c == true)
								{
									String relatedList = null;
									query = 'SELECT Id, (' + query + ' FROM ';
									if (ContextID != null && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '' && ContextID.AccountID != null)
									{
										query += eit.ParentAccountIDField__c;
										if (selectorQuery != null) query += ' WHERE ' + selectorQuery;
										if (eit.ObjectType__c.equalsIgnoreCase('ActivityHistory'))
										{
											query += ' ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + ContextID.AccountID + '\'';
										}
										else if (eit.ObjectType__c.equalsIgnoreCase('OpenActivity'))
										{
											query += ' ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + ContextID.AccountID + '\'';
										}
										else
										{
											query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + ContextID.AccountID + '\'';
										}
										relatedList = eit.ParentAccountIDField__c;
									}
									else if (ContextID != null && eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && ContextID.ContactID != null)
									{
										query += eit.ParentContactIDField__c;
										if (selectorQuery != null) query += ' WHERE ' + selectorQuery;
										if (eit.ObjectType__c.equalsIgnoreCase('ActivityHistory'))
										{
											query += ' ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + ContextID.ContactID + '\'';
										}
										else if (eit.ObjectType__c.equalsIgnoreCase('OpenActivity'))
										{
											query += ' ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + ContextID.ContactID + '\'';
										}
										else
										{
											query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + ContextID.ContactID + '\'';
										}
										relatedList = eit.ParentContactIDField__c;
									}
									else if (PrimaryID != null && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '' && PrimaryID.AccountID != null)
									{
										query += eit.ParentAccountIDField__c;
										if (selectorQuery != null) query += ' WHERE ' + selectorQuery;
										if (eit.ObjectType__c.equalsIgnoreCase('ActivityHistory'))
										{
											query += ' ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + PrimaryID.AccountID + '\'';
										}
										else if (eit.ObjectType__c.equalsIgnoreCase('OpenActivity'))
										{
											query += ' ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + PrimaryID.AccountID + '\'';
										}
										else
										{
											query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Account WHERE Id = \'' + PrimaryID.AccountID + '\'';
										}
										relatedList = eit.ParentAccountIDField__c;
									}
									else if (PrimaryID != null && eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && PrimaryID.ContactID != null)
									{
										query += eit.ParentContactIDField__c;
										if (selectorQuery != null) query += ' WHERE ' + selectorQuery;
										if (eit.ObjectType__c.equalsIgnoreCase('ActivityHistory'))
										{
											query += ' ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + PrimaryID.ContactID + '\'';
										}
										else if (eit.ObjectType__c.equalsIgnoreCase('OpenActivity'))
										{
											query += ' ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + PrimaryID.ContactID + '\'';
										}
										else
										{
											query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM Contact WHERE Id = \'' + PrimaryID.ContactID + '\'';
										}
										relatedList = eit.ParentContactIDField__c;
									}
									else continue;  // not enough info to do a successful query
									// System.Debug('###### ' + query);
									objs = Database.query(query);
									// System.Debug('###### ' + objs);
									if (objs != null) objs = objs[0].getSObjects(relatedList);
								}
								else
								{
									query += ' FROM ' + eit.ObjectType__c;
									if (eit.AccountContactMatching__c != null && eit.AccountContactMatching__c == 'AND')
									{
										if (eit.ParentContactIDField__c == null || eit.ParentAccountIDField__c == null
											|| eit.ParentContactIDField__c == '' || eit.ParentAccountIDField__c == ''
											|| ContactID == null || AccountID == null)
											continue;  //  don't even bother querying: need both fields to match
										if (ContactID.IsPersonAccount && AccountID.IsPersonAccount)
											query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + ContactID.ContactID + '\', \'' + AccountID.ContactID + '\') AND ' + eit.ParentAccountIDField__c + ' IN (\'' + AccountID.AccountID + '\', \'' + ContactID.AccountID + '\')';
										//else if (ContactID.IsPersonAccount)
										//	query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' AND ' + eit.ParentAccountIDField__c + ' IN (\'' + AccountID.AccountID + '\', \'' + ContactID.AccountID + '\')';
										//else if (AccountID.IsPersonAccount)
										//	query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + ContactID.ContactID + '\', \'' + AccountID.ContactID + '\') AND ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\')';
										else
											query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' AND ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\'';
									}
									else if (eit.AccountContactMatching__c != null && eit.AccountContactMatching__c == 'ORC')  // Account Must Match, Contact Matches or Is Blank
									{
										if (eit.ParentAccountIDField__c == null || eit.ParentAccountIDField__c == '' || AccountID == null)
										{
											if (ContactID != null && ContextID == null && eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '')
											{
												// if Contact ID is passed and there is no Account at all, then we'll be generous and let this slip through:
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\'';
											}
											else continue;  // don't even bother querying: need Account field to match
										}
										else if (eit.ParentContactIDField__c == null || eit.ParentContactIDField__c == '' || ContactID == null)
										{
											if (AccountID.IsPersonAccount && eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '')
												query += ' WHERE (' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\' OR ' + eit.ParentContactIDField__c + ' = \'' + AccountID.ContactID + '\')';
											else
												query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\'';
										}
										else if (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '')
										{
											if (AccountID.IsPersonAccount)
												query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\' AND ('
													+ eit.ParentContactIDField__c + ' IN (\'' + ContactID.ContactID + '\', \'' + AccountID.ContactID + '\') OR ' + eit.ParentContactIDField__c + ' = null)';
											else
												query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\' AND ('
													+ eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' OR ' + eit.ParentContactIDField__c + ' = null)';
										}
										else continue;
									}
									else if (eit.AccountContactMatching__c != null && eit.AccountContactMatching__c == 'ORA')  // Contact Must Match, Account Matches or Is Blank
									{
										if (eit.ParentContactIDField__c == null || eit.ParentContactIDField__c == '' || (ContactID == null && (AccountID == null || !AccountID.IsPersonAccount)))
										{
											if (AccountID != null && ContextID == null && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '')
											{
												// if Account ID is passed and there is no Contact at all, then we'll be generous and let this slip through:
												query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\'';
											}
											else continue;  //  don't even bother querying: need Contact field to match
										}
										else if (eit.ParentAccountIDField__c == null || eit.ParentAccountIDField__c == '')
										{
											if (ContactID == null)
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + AccountID.ContactID + '\'';
											//else if (AccountID != null && AccountID.IsPersonAccount)
											//	query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + ContactID.ContactID + '\', \'' + AccountID.ContactID + '\')';
											else
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\'';
										}
										else
										{
											if (ContactID == null)
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + AccountID.ContactID + '\'';
											else if (AccountID == null && ContactID.IsPersonAccount)
												query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' OR ' + eit.ParentAccountIDField__c + ' = \'' + ContactID.AccountID + '\')';
											else if (AccountID == null)
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\'';
											else
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' AND ('
													+ eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\' OR ' + eit.ParentAccountIDField__c + ' = null)';
										}
									}
									else if (eit.AccountContactMatching__c != null && eit.AccountContactMatching__c == 'CTX' && ContextID != null &&
									          (
									              (eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '' && ContextID.AccountID != null) || 
									              (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && ContextID.ContactID != null)
									          ))
									{
										if (ContextID.IsPersonAccount && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '' &&
											eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '')
											query += ' WHERE (' + eit.ParentAccountIDField__c + ' = \'' + ContextID.AccountID + '\' OR ' + eit.ParentContactIDField__c + ' = \'' + ContextID.ContactID + '\')';
										else if (ContextID.AccountID != null)
											query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + ContextID.AccountID + '\'';
										else if (ContextID.ContactID != null)
											query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContextID.ContactID + '\'';
										else continue;
									}
									else  //  default OR logic
									{
										if (eit.ParentContactIDField__c != null && eit.ParentAccountIDField__c != null
											&& eit.ParentContactIDField__c != '' && eit.ParentAccountIDField__c != ''
											&& PrimaryID != null && ContextID != null)
										{
											if (eit.ParentContactIDField__c == eit.ParentAccountIDField__c)
											{
												if (PrimaryID.IsPersonAccount && ContextID.IsPersonAccount)
													query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ContactID + '\', \'' + PrimaryID.AccountID + '\', \'' + ContextID.ContactID + '\', \'' + ContextID.AccountID + '\')';
												else if (PrimaryID.IsPersonAccount)
													query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ContactID + '\', \'' + PrimaryID.AccountID + '\', \'' + ContextID.ID + '\')';
												else if (ContextID.IsPersonAccount)
													query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ID + '\', \'' + ContextID.ContactID + '\', \'' + ContextID.AccountID + '\')';
												else
													query += ' WHERE ' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ID + '\', \'' + ContextID.ID + '\')';
											}
											else
											{
												if (PrimaryID.IsPersonAccount && ContextID.IsPersonAccount)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ContactID + '\', \'' + ContextID.ContactID + '\') OR ' +
														eit.ParentAccountIDField__c + ' IN (\'' + PrimaryID.AccountID + '\', \'' + ContextID.AccountID + '\'))';
												else if (PrimaryID.IsPersonAccount && ContextID.ContactID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ContactID + '\', \'' + ContextID.ContactID + '\') OR ' +
														eit.ParentAccountIDField__c + ' = \'' + PrimaryID.AccountID+ '\')';
												else if (PrimaryID.IsPersonAccount && ContextID.AccountID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + PrimaryID.ContactID + '\' OR ' +
														eit.ParentAccountIDField__c + ' IN (\'' + PrimaryID.AccountID+ '\', \'' + ContextID.AccountID + '\'))';
												else if (ContextID.IsPersonAccount && PrimaryID.ContactID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' IN (\'' + PrimaryID.ContactID + '\', \'' + ContextID.ContactID + '\') OR ' +
														eit.ParentAccountIDField__c + ' = \'' + ContextID.AccountID+ '\')';
												else if (ContextID.IsPersonAccount && PrimaryID.AccountID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + ContextID.ContactID + '\' OR ' +
														eit.ParentAccountIDField__c + ' IN (\'' + PrimaryID.AccountID+ '\', \'' + ContextID.AccountID + '\'))';
												else if (PrimaryID.AccountID != null && ContextID.ContactID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + ContextID.ContactID + '\' OR ' +
														eit.ParentAccountIDField__c + ' = \'' + PrimaryID.AccountID+ '\')';
												else if (PrimaryID.ContactID != null && ContextID.AccountID != null)
													query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + PrimaryID.ContactID + '\' OR ' +
														eit.ParentAccountIDField__c + ' = \'' + ContextID.AccountID+ '\')';
												else continue;
											}
										}
										else if (eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '' && AccountID != null)
										{
											if (AccountID.IsPersonAccount && eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '')
												query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + AccountID.ContactID + '\' OR ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\')';
											else
												query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + AccountID.AccountID + '\'';
										}
										else if (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && ContactID != null)
										{
											if (ContactID.IsPersonAccount && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '')
												query += ' WHERE (' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\' OR ' + eit.ParentAccountIDField__c + ' = \'' + ContactID.AccountID + '\')';
											else
												query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + ContactID.ContactID + '\'';
										}
										else if (eit.ParentContactIDField__c != null && eit.ParentContactIDField__c != '' && AccountID != null && AccountID.IsPersonAccount)
											query += ' WHERE ' + eit.ParentContactIDField__c + ' = \'' + AccountID.ContactID + '\'';
										else continue;  //  IMPORTANT: if there is no criteria, it will select everything, so we must continue
									}
									if (selectorQuery != null) query += ' AND ' + selectorQuery;
									query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit);
									// System.Debug('###### ' + query);
									objs = Database.query(query);
									// System.Debug('###### ' + objs);
								}
							}
							else
							{
								//
								//  custom timeline
								//
								if (eit.ExecuteAsSubquery__c == true)
								{
									String relatedList = null;
									if (PrimaryID != null && eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != '')
									{
										query = 'SELECT Id, (' + query + ' FROM ';
										query += eit.ParentAccountIDField__c;
										if (selectorQuery != null) query += ' WHERE ' + selectorQuery;
										if (eit.ObjectType__c.equalsIgnoreCase('ActivityHistory'))
										{
											query += ' ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM ' + TimelineObject + ' WHERE Id = \'' + PrimaryID.ID + '\'';
										}
										else if (eit.ObjectType__c.equalsIgnoreCase('OpenActivity'))
										{
											query += ' ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM ' + TimelineObject + ' WHERE Id = \'' + PrimaryID.ID + '\'';											
										}
										else
										{
											query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit) + ') FROM ' + TimelineObject + ' WHERE Id = \'' + PrimaryID.ID + '\'';
										}
										relatedList = eit.ParentAccountIDField__c;
									}
									else continue;  //  not enough info to do a successful query
									// System.Debug('###### ' + query);
									objs = Database.query(query);
									// System.Debug('###### ' + objs);
									if (objs != null) objs = objs[0].getSObjects(relatedList);
								}
								else
								{
									query += ' FROM ' + eit.ObjectType__c;
									if (eit.ParentAccountIDField__c != null && eit.ParentAccountIDField__c != ''
										&& PrimaryID != null)
									{
										query += ' WHERE ' + eit.ParentAccountIDField__c + ' = \'' + PrimaryID.ID + '\'';
									}
									else continue;  //  IMPORTANT: if there is no criteria, it will select everything, so we must continue
									if (selectorQuery != null) query += ' AND ' + selectorQuery;
									query += ' ORDER BY ' + eit.StartTimeValue__c + ' DESC LIMIT ' + String.valueOf(RecordLimit);
									// System.Debug('###### ' + query);
									objs = Database.query(query);
									// System.Debug('###### ' + objs);
								}
							}
							if (objs != null) for (SObject obj : objs)
							{
								//  get record ID
								String objids = (String)getValue(obj, recordIDField);
								if (objids == null) continue;
								Id objid = Id.valueOf(objids);

								//  determine timeline times and dates
								DateTime startTime;
								DateTime endTime;
								if (startTimeType == Schema.DisplayType.Date)
								{
									Date sd = (Date)getValue(obj, eit.StartTimeValue__c);
									if (sd != null) startTime = DateTime.newInstance(sd, midnight);
								}
								else
								{
									startTime = (DateTime)getValue(obj, eit.StartTimeValue__c);
								}
								if (endTimeType == Schema.DisplayType.Date)
								{
									Date ed = (Date)getValue(obj, eit.EndTimeValue__c);
									if (ed != null) endTime = DateTime.newInstance(ed, midnight);
								}
								else
								{
									endTime = (DateTime)getValue(obj, eit.EndTimeValue__c);
								}
								if (startTime == null) startTime = endTime;
								if (startTime == endTime) endTime = null;
								else if (endTime != null && endTime < startTime)
								{
									//  swap backward dates
									DateTime temp = startTime;
									startTime = endTime;
									endTime = temp;
								}
								if (startTime == null) continue;  //  cannot be displayed on the timeline

								if (timeline.lastEvent == null || timeline.lastEvent < startTime) timeline.lastEvent = startTime;
								if ((timeline.lastPastEvent == null || timeline.lastPastEvent < startTime) && startTime < now) timeline.lastPastEvent = startTime;

								//  check for duplicates from multiple trackers to avoid timeline clutter
								if (eventMap.containsKey(objid))
								{
									// if (PrimaryID != null && objid != PrimaryID.ID) continue;
									event e2 = (event)eventMap.get(objid);
									if ((e2.start == startTime || e2.end_reservedKeyword == startTime) && e2.link == ('/' + objid))
										continue;  //  avoid duplicate events
								}
								if (inclusionFieldType != null)
								{
									Object iof = getValue(obj, eit.InclusionField__c);
									if (iof == null) continue;
									if (inclusionFieldType == Schema.DisplayType.ID || inclusionFieldType == Schema.DisplayType.String || inclusionFieldType == Schema.DisplayType.TextArea || inclusionFieldType == Schema.DisplayType.Combobox || inclusionFieldType == Schema.DisplayType.Picklist || inclusionFieldType == Schema.DisplayType.Email || inclusionFieldType == Schema.DisplayType.URL || inclusionFieldType == Schema.DisplayType.MultiPicklist)
									{
										String temp = (String)iof;
										if (temp == '' || temp == '0' || temp == ';' || temp.equalsIgnoreCase('false') || temp.equalsIgnoreCase('no')) continue;
									}
									else if (inclusionFieldType == Schema.DisplayType.Integer)
									{
										if ((Integer)iof == 0) continue;
									}
									else if (inclusionFieldType == Schema.DisplayType.Double || inclusionFieldType == Schema.DisplayType.Currency || inclusionFieldType == Schema.DisplayType.Percent)
									{
										if ((Double)iof == 0) continue;
									}
									else if (inclusionFieldType == Schema.DisplayType.Boolean)
									{
										if ((Boolean)iof == false) continue;
									}
								}


								String name = (String)getValue(obj, eit.RecordNameField__c);

								event e = new event();
								e.title = name;
								e.eit = eit.Id;

								String descr = (String)getValue(obj, eit.DescriptionField__c);
								e.caption = objLabel + e.title;
								if (eit.HoverField__c != null && eit.HoverField__c != '' && eit.HoverField__c != eit.RecordNameField__c)
								{
									String hoverValue;
									Object hof = getValue(obj, eit.HoverField__c);
									if (hof == null)
										hoverValue = null;
									else if (hoverFieldType == Schema.DisplayType.Currency)
										hoverValue = getCurrencySymbol(getObject(obj, eit.HoverField__c)) + (((Decimal)hof).setScale(2) + .001).format().removeEnd('1');
									else if (hoverFieldType == Schema.DisplayType.Percent)
										hoverValue = ((Decimal)hof).setScale(1).format() + '%';
									else
										hoverValue = String.valueOf(hof);
									//  swap the hover value and title if the title is blank
									if ((e.title == null || e.title == '') && hoverValue != null && hoverValue != '')
									{
										e.title = hoverValue;
										hoverValue = null;
									}

									if (hoverValue != null && hoverValue != '' && hoverValue != e.title)
										e.caption += ': ' + hoverValue;
								}
								if (descr != null)
								{
									//  this is not a thorough check for HTML markup: this should be hardened - TO DO
									if (!descr.contains('<'))
									{
										descr = descr.replaceAll('\r\n', '<br />').replaceAll('\n', '<br />').replaceAll('\r', '<br />');
									}
								}
								e.description = descr;
								e.link = urlPrefix + '/' + objid;
								e.start = startTime;
								e.end_reservedKeyword = endTime;
								if (eit.Color__c != null && eit.Color__c.right(3) == '__c') e.color = (String)obj.get(eit.Color__c);
								else e.color = eit.Color__c;
								if (eit.TextColor__c != null && eit.TextColor__c.right(3) == '__c') e.textColor = (String)obj.get(eit.TextColor__c);
								else e.textColor = eit.TextColor__c;
								if (eit.Icon__c != null && eit.Icon__c.right(3) == '__c') e.icon = (String)obj.get(eit.Icon__c);
								else e.icon = eit.Icon__c;
								if (eit.Image__c != null && eit.Image__c.right(3) == '__c') e.image = (String)obj.get(eit.Image__c);
								else e.image = eit.Image__c;
								if (e.image == null || e.image == '') e.image = e.icon;
								if (eit.TapeImage__c != null && eit.TapeImage__c.right(3) == '__c') e.tapeImage = (String)obj.get(eit.TapeImage__c);
								else e.tapeImage = eit.TapeImage__c;
								if (e.icon != null && e.icon.StartsWith('/')) e.icon = urlPrefix + e.icon;  // for Communities
								if (e.image != null && e.image.StartsWith('/')) e.image = urlPrefix + e.image;  // for Communities
								if (e.tapeImage != null && e.tapeImage.StartsWith('/')) e.tapeImage = urlPrefix + e.tapeImage;  // for Communities
								e.tapeRepeat = eit.TapeRepeat__c;
								if (eit.Category__c != null)
								{
									EventCategory ec = (EventCategory)EventCategoryMap.get(eit.Category__c);
									if (ec != null) e.classname = ec.classname;
								}
								//  e.durationEvent = false;


								//
								//  customer disposition calculation
								//
								if (eit.CustSatField__c != null && eit.CustSatField__c != '' && eit.CustSatWorst__c != null && eit.CustSatBest__c != null && eit.CustSatWorst__c != eit.CustSatBest__c && e.start != null)
								{
									Double csat = (Double)getValue(obj, eit.CustSatField__c);
									if (csat == null && eit.CustSatEmptyNeutral__c == true) csat = offset;
									if (csat != null)
									{
										Double csat_normalized = (csat - offset) * 2.0 / range;  // normalize to -1.0 to 1.0 range
										csat_normalized = Math.max(Math.min(csat_normalized,1.0),-1.0);
										e.custSat = csat_normalized;
										Double halfLifeFactor = 1.0;
										if (eit.CustSatHalfLife__c != null && eit.CustSatHalfLife__c != 0)
										{
											Double age = nowday - (e.start.getTime() / 86400000.0);  // age in days
											// csat_normalized = csat_normalized * Math.pow((Double)(0.5), age / (Double)eit.CustSatHalfLife__c);  // half life applied
											halfLifeFactor = Math.pow((Double)(0.5), age / (Double)eit.CustSatHalfLife__c);  // half life applied
										}
										eitsat = ((eitsat * eitsatcount) + (csat_normalized * halfLifeFactor)) / (eitsatcount + halfLifeFactor);
										eitsatcount += halfLifeFactor;
									}
								}


								if (csatonly != true && eit.CustSatOnly__c != true) timeline.events.add(e);  // no need to create a timeline event
								eventMap.put(objid, e);

							}
							//  aggregate customer disposition across trackers
							if (eit.CustSatWeighting__c != null) eitsatcount = eitsatcount * eit.CustSatWeighting__c;
							if (eitsatcount > 0)
							{
								totalsat = ((totalsat * totalsatcount) + (eitsat * eitsatcount)) / (totalsatcount + eitsatcount);
								totalsatcount += eitsatcount;
							}

							//  make sure user has ability to view the record, per org sharing rules
							Integer ecount = timeline.events.size();
							if (ecount > 0)
							{
								List<Id> recids = new List<Id>();
								Map<Id, Boolean> recaccess = new Map<Id, Boolean>();

								//  load read UserRecordAccess into recaccess in 200-record chunks
								Integer chunksize = 0;
								for (event ev : timeline.events)
								{
									if (ev != null && ev.link != null)
									{
										String idcand = ev.link.substring(ev.link.lastIndexOf('/')+1);
										if (idcand instanceof Id)
										{
											recids.add(Id.valueOf(idcand));
											chunksize++;
										}
									}
									if (chunksize == 200)
									{
										List<UserRecordAccess> uras = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recids LIMIT 200];
										if (uras != null) for (UserRecordAccess ura : uras)
											recaccess.put(ura.RecordId, ura.HasReadAccess);
										recids.clear();
										chunksize = 0;
									}
								}
								if (chunksize > 0)
								{
									List<UserRecordAccess> uras = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recids LIMIT 200];
									if (uras != null) for (UserRecordAccess ura : uras)
										recaccess.put(ura.RecordId, ura.HasReadAccess);
								}

								//  remove any records to which the user does not have access
								for (Integer i = 0; i < ecount; i++)
								{
									event ev = timeline.events.get(i);
									if (ev != null && ev.link != null)
									{
										String idcand = ev.link.substring(ev.link.lastIndexOf('/')+1);
										if (idcand instanceof Id)
										{
											Boolean isAccessible = recaccess.get(Id.valueOf(idcand));
											if (!isAccessible)
											{
												timeline.events.remove(i);
												i--;
												ecount--;
											}
										}
										ev.eit = null;
									}
								}
							}
						}
						catch (Exception e)
						{
							System.Debug('####### ERROR in processing Event Tracker ' + eit.Name + ': ' + e.getMessage() + ' on line ' + e.getLineNumber());
							//  remove all timeline events of this EIT
							Integer ecount = timeline.events.size();
							for (Integer i = 0; i < ecount; i++)
							{
								event ev = timeline.events.get(i);
								if (ev != null && ev.eit != null && ev.eit == eit.Id)
								{
									timeline.events.remove(i);
									i--;
									ecount--;
								}
							}
							Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
							mail.setTargetObjectId(eit.OwnerId);
							mail.setSaveAsActivity(false);
							mail.setReplyTo('no-reply@salesforce.com');
							mail.setSenderDisplayName('Salesforce Timeline');
							mail.setSubject('Timeline Error from Org : ' + UserInfo.getOrganizationName());
							String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
							String returnURL = EncodingUtil.urlEncode(Page.List.getUrl()
								+ (TimelineObject != null && TimelineObject != '' ? '?timeline=' + TimelineObject : ''), 'UTF-8');
							mail.setPlainTextBody
							(
								'There was a runtime error when ' + UserInfo.getName()
								+ ' (' + UserInfo.getUserName() + ') '
								+ 'attempted to render a timeline with the Event "'
								+ eit.Name + '", triggered on line ' + e.getLineNumber() + '.\n\n'
								+ 'Error: ' + e.getMessage() + '\n\n'
								+ 'Encountered with primary ID ' + (PrimaryID != null && PrimaryID.ID != null ? PrimaryID.ID : 'null')
									+ (ContactID != null && (PrimaryID == null || ContactID.ContactID != PrimaryID.ID) ? ', contact ID ' + ContactID.ContactID : '')
									+ (AccountID != null && (PrimaryID == null || AccountID.AccountID != PrimaryID.ID) ? ', account ID ' + AccountID.AccountID : '') + '.\n\n'
								+ (PrimaryID != null && PrimaryID.AccountID == null && PrimaryID.ContactID == null ? 'View Object as ' + baseURL + '/' + PrimaryID.ID + '.\n\n' : '')
								+ (ContactID != null ? 'View Contact as ' + baseURL + '/' + ContactID.ContactID + '.\n\n' : '')
								+ (AccountID != null ? 'View Account as ' + baseURL + '/' + AccountID.AccountID + '.\n\n' : '')
								+ 'Edit Tracker at ' + baseURL + Page.Edit.getUrl() + '?id=' + eit.Id
									+ (TimelineObject != null && TimelineObject != '' ? '&timeline=' + TimelineObject : '')
									+ '&retURL=' + returnURL
									+ '&saveURL=' + returnURL
									+ '&cancelURL=' + returnURL + '.\n\n'
								+ 'View Timeline as ' + baseURL + Page.Timeline.getUrl() + '?id=' + (PrimaryID != null ? PrimaryID.ID : '')
									+ (ContextID != null ? '&xid=' + ContextID.ID : '')
								+ '.'
							);
							errorNotifications.add(mail);
						}
						if (totalsatcount > 0) timeline.customerSatScore = totalsat;
					}
					if (errorNotifications.size() > 0)
					{
						try
						{
							Messaging.sendEmail(errorNotifications);
						}
						catch (Exception e)
						{
						}
					}
				}
			}
			return timeline;
		}
		set;
	}


	global String JSONEventsString
	{
		get
		{
			if (JSONEventsString == null)
			{
				if (timeline != null)
				{
					if (csatonly) JSONEventsString = String.valueOf(timeline.customerSatScore);
					else JSONEventsString = JSON.serialize(timeline).replace('end_reservedKeyword','end')
						.replace(',"eit":null', '');
				}
			}
			return JSONEventsString;
		}
		set;
	}

	public String Timezone
	{
		get
		{
			if (Timezone == null)
			{
				Datetime now = Datetime.now();
				Decimal localHour = (Decimal)now.hour() + ((Decimal)now.minute() / 60.0);
				Decimal GMTHour = (Decimal)now.hourGmt() + ((Decimal)now.minuteGmt() / 60.0);
				Decimal offset = localHour - GMTHour;
				if (offset > 12) offset -= 24;
				else if (offset < -12) offset += 24;
				offset *= 2.0;
				offset = offset.round();
				offset = offset / 2.0;
				Timezone = offset.toPlainString();
			}
			return Timezone;
		}
		set;
	}

	static private String getCurrencyIsoCode(SObject someObject)
	{
		String currencyIso = UserInfo.isMultiCurrencyOrganization() ? (String) someObject.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency();
		return currencyIso;
	}

	static private String getCurrencySymbol(SObject someObject)
	{
		return getCurrencySymbolFromIso(getCurrencyIsoCode(someObject));
	}

	static private String getCurrencySymbolFromIso(String iso)
	{
		String symbol = iso;
		if (iso=='USD') { symbol='$'; }
		else if (iso=='CAD') { symbol='$'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='GBP') { symbol='£'; }
		else if (iso=='JPY') { symbol='¥'; }
		else if (iso=='EGP') { symbol='£'; }
		else if (iso=='ALL') { symbol='Lek'; }
		else if (iso=='ANG') { symbol='ƒ'; }
		else if (iso=='ARS') { symbol='$'; }
		else if (iso=='AUD') { symbol='$'; }
		else if (iso=='AWG') { symbol='ƒ'; }
		else if (iso=='BAM') { symbol='KM'; }
		else if (iso=='BBD') { symbol='$'; }
		else if (iso=='BMD') { symbol='$'; }
		else if (iso=='BND') { symbol='$'; }
		else if (iso=='BOB') { symbol='$b'; }
		else if (iso=='BRL') { symbol='R$'; }
		else if (iso=='BSD') { symbol='$'; }
		else if (iso=='BWP') { symbol='P'; }
		else if (iso=='BYR') { symbol='p.'; }
		else if (iso=='BZD') { symbol='BZ$'; }
		else if (iso=='CHF') { symbol='CHF'; }
		else if (iso=='CHF') { symbol='CHF'; }
		else if (iso=='CLP') { symbol='$'; }
		else if (iso=='CNY') { symbol='¥'; }
		else if (iso=='COP') { symbol='$'; }
		else if (iso=='CRC') { symbol='¢'; }
		else if (iso=='CZK') { symbol='Kc'; }
		else if (iso=='DKK') { symbol='kr'; }
		else if (iso=='DOP') { symbol='RD$'; }
		else if (iso=='EEK') { symbol='kr'; }
		else if (iso=='FJD') { symbol='$'; }
		else if (iso=='FKP') { symbol='£'; }
		else if (iso=='GGP') { symbol='£'; }
		else if (iso=='GHC') { symbol='¢'; }
		else if (iso=='GIP') { symbol='£'; }
		else if (iso=='GTQ') { symbol='Q'; }
		else if (iso=='GYD') { symbol='$'; }
		else if (iso=='HKD') { symbol='$'; }
		else if (iso=='HNL') { symbol='L'; }
		else if (iso=='HRK') { symbol='kn'; }
		else if (iso=='HUF') { symbol='Ft'; }
		else if (iso=='IDR') { symbol='Rp'; }
		else if (iso=='IMP') { symbol='£'; }
		else if (iso=='ISK') { symbol='kr'; }
		else if (iso=='JEP') { symbol='£'; }
		else if (iso=='JMD') { symbol='J$'; }
		else if (iso=='KYD') { symbol='$'; }
		else if (iso=='LBP') { symbol='£'; }
		else if (iso=='LRD') { symbol='$'; }
		else if (iso=='LTL') { symbol='Lt'; }
		else if (iso=='LVL') { symbol='Ls'; }
		else if (iso=='MXN') { symbol='$'; }
		else if (iso=='MYR') { symbol='RM'; }
		else if (iso=='MZN') { symbol='MT'; }
		else if (iso=='NAD') { symbol='$'; }
		else if (iso=='NIO') { symbol='C$'; }
		else if (iso=='NOK') { symbol='kr'; }
		else if (iso=='NZD') { symbol='$'; }
		else if (iso=='PAB') { symbol='B/.'; }
		else if (iso=='PEN') { symbol='S/.'; }
		else if (iso=='PHP') { symbol='Php'; }
		else if (iso=='PLN') { symbol='zl'; }
		else if (iso=='PYG') { symbol='Gs'; }
		else if (iso=='RON') { symbol='lei'; }
		else if (iso=='SBD') { symbol='$'; }
		else if (iso=='SEK') { symbol='kr'; }
		else if (iso=='SGD') { symbol='$'; }
		else if (iso=='SHP') { symbol='£'; }
		else if (iso=='SOS') { symbol='S'; }
		else if (iso=='SRD') { symbol='$'; }
		else if (iso=='SVC') { symbol='$'; }
		else if (iso=='SYP') { symbol='£'; }
		else if (iso=='TRL') { symbol='£'; }
		else if (iso=='TRY') { symbol='TL'; }
		else if (iso=='TTD') { symbol='TT$'; }
		else if (iso=='TVD') { symbol='$'; }
		else if (iso=='TWD') { symbol='NT$'; }
		else if (iso=='UYU') { symbol='$U'; }
		else if (iso=='VEF') { symbol='Bs'; }
		else if (iso=='XCD') { symbol='$'; }
		else if (iso=='ZAR') { symbol='R'; }
		else if (iso=='ZWD') { symbol='Z$'; }

		return symbol;
	}

	static private String queryAddFields(String query, String[] fields)
	{
		if (query == null || fields == null || query.length() < 7 || fields.size() < 1) return query;
		String combo = '';
		Integer counter = 0;
		Set<String> fieldNames = new Set<String>();
		for (String field : fields)
		{
			if (field == null || field == '') continue;
			if (fieldNames.contains(field.toUpperCase())) continue;  // prevent duplicates
			fieldNames.add(field.toUpperCase());
			if (field != null && field != '')
				combo += (counter > 0 ? ', ' : '') + field;
			counter++;
		}
		fieldNames.clear();
		return query + combo;
	}

	public class EventCategory implements Comparable
	{
		public String classname { get; set; }
		public String label { get; set; }
		public Boolean visible { get; set; }
		public Id Id { get; set; }
		public EventCategory(String classname, String label, Boolean visible, Id id)
		{
			this.classname = classname;
			this.label = label;
			this.visible = visible;
			this.Id = id;
		}
		public Integer compareTo(Object compareTo)
		{
			return label.compareTo(((EventCategory)compareTo).label);
		}
	}

	public List<EventCategory> EventCategories
	{
		get
		{
			if (EventCategories == null)
			{
				EventCategories = new List<EventCategory>();
				if (EIT_Categories != null) for (Category__c cat : EIT_Categories)
				{
					EventCategory ec = new EventCategory(cat.Name.replaceAll('[^a-zA-Z]+', '-'), cat.Name, cat.DefaultVisibility__c, cat.Id);
					EventCategories.add(ec);
				}
			}
			return EventCategories;
		}
		set;
	}

	public Integer CategoryCount
	{
		get
		{
			if (CategoryCount == null)
			{
				CategoryCount = EventCategories.size();
			}
			return CategoryCount;
		}
		set;
	}

	private Map<Id, EventCategory> EventCategoryMap
	{
		get
		{
			if (EventCategoryMap == null)
			{
				EventCategoryMap = new Map<Id, EventCategory>();
				for (EventCategory ec : EventCategories)
				{
					EventCategoryMap.put(ec.Id, ec);
				}
			}
			return EventCategoryMap;
		}
		set;
	}

	global Timeline()
	{
		CustID pID = this.PrimaryID;
		CustID cID = this.ContextID;
	}

	public Timeline(ApexPages.StandardController stdController)
	{
		// SObject obj = stdController.getRecord();
		// ContextID = (String)obj.Id;
		CustID pID = this.PrimaryID;
		CustID cID = this.ContextID;
	}


}