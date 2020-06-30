Updated: 2020-06-18

Views
-----------------
- Normally one table per view, unless derived tables are used. 
- Defines the table in terms of dimension & measure fields.

	Creating a view
	-----------------
	view: some_name {
	view_label: label
	sql_table_name: `project.schema.table` ;;
	derived_table: {sql: SELECT * FROM table1 UNION ALL SELECT * FROM table2 ;;}
	...
	dimension/measure definitions
	...
	}
	
	Adding dimensions
	-----------------
	dimension: field1 {
		type: string
		label: "Label"
		group_label: "Group Label"	
		description: "Field description"
		sql: ${TABLE}.column1 ;;
	}
	
	dimension: dimension_tier {
		type: tier
		tiers: [0, 10, 20, 30, 40, 50]
		style: integer
		sql: ${field1} ;;
	}

	dimension_group: date {
		group_label: "Date"
		type: time
		timeframes: [
		  raw,
		  time,
		  date,
		  week,
		  month,
		  quarter,
		  year
		]
		sql: ${TABLE}.date_field ;;
	}
	
	dimension: hyperlinked_dimension { 
		type: string 
		html:  <a href= "{{ view_name.dimension_hyperlink._value }}" target="_blank">  Label: {{ view_name.dimension_label._value }}  </a>  ;; 
		sql: ${TABLE}.link_jira_url ;; 
	}
	
	measure: field1_mes { # dimensions can be turned into measures by aggregating
		type: sum
		sql: ${field1}
	}
	
	filters - only works with measure types that aggregate
	-----------------
	measure: filtered_count {
	  type: count
	  filters: {
		field: field1
		value: "value"
	  }
	}

	dimension: filtered_dimension {
	  type: yesno
	  sql: (CASE WHEN ${dimension1} = 'value' AND ${dimension2} = 'value' THEN 1 ELSE 0 END) ;;
	}

	Aliases - a way to make Looker asign multiple field names to one definition
	-----------------
	dimension: dim1 {
		alias: [alternative_field_name]
		type: string
		sql: ${TABLE}.column1 ;;
	}
	
	Parameters
	-----------------
	  parameter: timeframe_picker { # Defines allowed values in a drop-down
		type: string
		allowed_value: {value: "Date"}
		allowed_value: {value: "Year"}
	  }

	  dimension: dynamic_timeframe { # Dynamically adjusts the dimension based on the allowed value chosen
		type: string
		sql:
			{% if timeframe_picker._parameter_value == "'Date'" %}                        	    	CAST(${date_field_date} AS string)
			{% elsif timeframe_picker._parameter_value == "'Year'" %}                               CAST(${date_field_year} AS string)
		  {% endif %} ;;
	  }

	  parameter: period_offset_picker { # Defines allowed period-on-period comparison choices
		type: string
		allowed_value: {value: "YoY"}
		allowed_value: {value: "DoD"}
	  }

	  dimension: dynamic_period_offset { # Applies the correct period offset based on the period-on-period value chosen
		type: number
		sql:
		{% if timeframe_picker._parameter_value == "'Date'" %}
		  {% if period_offset_picker._parameter_value =="'YoY'" %}             -364
			{% elsif period_offset_picker._parameter_value == "'DoD'" %}         -1
			{% else %}                                                         -364
		  {% endif %}
		{% endif %}
		;;
	  }
	  
	  parameter: dimension_picker {
		type: string
		allowed_value: {value: "All values"}
		allowed_value: {value: "Value1"}
		allowed_value: {value: "Value2"}
	  }

	  dimension: dynamic_dimension {
		type: string
		sql:
			{% if dimension_picker._parameter_value == "'All values'" %}                                CAST(${all_values} AS string)
			{% elsif dimension_picker._parameter_value == "'Value1'" %}                      		  	CAST(${dimension1} AS STRING)
			{% elsif dimension_picker._parameter_value == "'Value2'" %}                  			  	CAST(${dimension1} AS STRING)
			{% elsif dimension_picker._parameter_value == "''" %}                                       CAST(NULL AS string)
		    {% endif %} ;;
	  }

	  parameter: metric_picker_1 {
		type: string
		allowed_value: {value: "Value1"}
		allowed_value: {value: "Value2"}
		allowed_value: {value: "Value3"}
	  }

	  measure: dynamic_metric_1 {
		type: number
		sql:
			{% if metric_picker_1._parameter_value == "'Value1'" %}                              	CAST(${measure1} AS string)
			{% elsif metric_picker_1._parameter_value == "'Value2'" %}                       		CAST(${measure2} AS string)
			{% elsif metric_picker_1._parameter_value == "'Value3'" %}                      		CAST(${measure3} AS string)
			{% elsif metric_picker_1._parameter_value == "''" %}                                 	CAST(${} AS string)
			{% endif %}
		;;
	  }
  
	parameter: dimension_picker { # references a dimension in another explore which references distinct values from source
		suggest_explore: dynamic_params
		suggest_dimension: dynamic_params.dynamic_dimension
	}
	
	
	Aggregate awareness - looker switches to different tables based on what fields have been selected
	-----------------
	sql_table_name:
	  {% if view_name.field_name1._in_query %}			table_a
	  {% elsif view_name.field_name2._in_query %}		table_a
	  {% elsif view_name.field_name3._in_query %}		table_b
	  {% else %}										table_c
	  {% endif %} ;;

Models
-----------------
- This is where these views are joined together to form an explore

	Creating an explore
	-----------------
	explore: my_explore { # needs to be the same name as the core view it's pulling from
		label: "Explore Label"
		always_filter: { # optional
			filters: {
			  field: date_field
			  value: "7 days"
			}
		}

		join: other_view {
		type: left_outer
		relationship: one_to_many # defines how Looker aggregates metrics (whether symmetric aggregation is necessary)
		sql_on: ${some_name.join_key} = ${other_view.join_key} ;;
		}
	}
	
	Data groups - used for assigning a caching policy to Explores and/or PDTs. 
	-----------------
	datagroup: my_datagroup {
	  sql_trigger:
		SELECT
		  MAX(date_field)
		FROM `project.schema.table`
		WHERE column1 = 'condition'
	  ;;
	  max_cache_age: "24 hours"
	}
	
	explore: my_explore {
		persists_with: my_datagroup
	{

Explores
-----------------
- The space used for developing dashboards
- Similar to writing your own bespoke query in Tableau, but Looker does it for you according to your model/view definitions


Dashboards
-----------------

	Tiles (types of)
	--------------
	Query tiles (independent from looks)
	Text tiles
	Look-linked tiles (linked to the original look)
	
	


Author: Konstantin

References:
https://shopify.github.io/liquid/basics/operators/
