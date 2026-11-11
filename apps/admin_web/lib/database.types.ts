
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "audit_log": {
                  Row: {
                    "action": string,"actor_id": string | null,"created_at": string,"details": NonNullable<Json>,"id": number,"school_id": string,"target_id": string | null,"target_type": string
                  }
                  ComputedFields: never
                  Insert: {
                    "action": string,"actor_id"?: string | null,"created_at"?: string,"details"?: NonNullable<Json>,"id"?: never,"school_id": string,"target_id"?: string | null,"target_type": string
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string | null,"created_at"?: string,"details"?: NonNullable<Json>,"id"?: never,"school_id"?: string,"target_id"?: string | null,"target_type"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "audit_log_actor_id_fkey"
      columns: ["actor_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "audit_log_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"buses": {
                  Row: {
                    "capacity": number,"created_at": string,"id": string,"in_service": boolean,"name": string | null,"plate": string,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "capacity": number,"created_at"?: string,"id"?: string,"in_service"?: boolean,"name"?: string | null,"plate": string,"school_id": string
                  }
                  Update: {
                    "capacity"?: number,"created_at"?: string,"id"?: string,"in_service"?: boolean,"name"?: string | null,"plate"?: string,"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "buses_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"departments": {
                  Row: {
                    "code": string | null,"created_at": string,"faculty_id": string,"id": string,"name": string,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "code"?: string | null,"created_at"?: string,"faculty_id": string,"id"?: string,"name": string,"school_id": string
                  }
                  Update: {
                    "code"?: string | null,"created_at"?: string,"faculty_id"?: string,"id"?: string,"name"?: string,"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "departments_faculty_id_school_id_fkey"
      columns: ["faculty_id","school_id"]
isOneToOne: false
      referencedRelation: "faculties"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "departments_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"device_tokens": {
                  Row: {
                    "created_at": string,"id": string,"last_seen_at": string,"locale": string,"platform": string,"school_id": string,"token": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"id"?: string,"last_seen_at"?: string,"locale"?: string,"platform": string,"school_id": string,"token": string,"user_id": string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"last_seen_at"?: string,"locale"?: string,"platform"?: string,"school_id"?: string,"token"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "device_tokens_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "device_tokens_user_id_school_id_fkey"
      columns: ["user_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"faculties": {
                  Row: {
                    "code": string | null,"created_at": string,"id": string,"name": string,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "code"?: string | null,"created_at"?: string,"id"?: string,"name": string,"school_id": string
                  }
                  Update: {
                    "code"?: string | null,"created_at"?: string,"id"?: string,"name"?: string,"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "faculties_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"interest_requests": {
                  Row: {
                    "created_at": string,"email": string,"id": string,"kind": string,"locale": string,"message": string | null,"name": string | null,"organisation": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"email": string,"id"?: string,"kind": string,"locale"?: string,"message"?: string | null,"name"?: string | null,"organisation"?: string | null
                  }
                  Update: {
                    "created_at"?: string,"email"?: string,"id"?: string,"kind"?: string,"locale"?: string,"message"?: string | null,"name"?: string | null,"organisation"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"live_positions": {
                  Row: {
                    "accuracy_m": number | null,"bus_id": string,"heading_deg": number | null,"location": unknown,"recorded_at": string,"school_id": string,"source": string,"speed_mps": number | null,"trip_id": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "accuracy_m"?: number | null,"bus_id": string,"heading_deg"?: number | null,"location": unknown,"recorded_at"?: string,"school_id": string,"source"?: string,"speed_mps"?: number | null,"trip_id"?: string | null
                  }
                  Update: {
                    "accuracy_m"?: number | null,"bus_id"?: string,"heading_deg"?: number | null,"location"?: unknown,"recorded_at"?: string,"school_id"?: string,"source"?: string,"speed_mps"?: number | null,"trip_id"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "live_positions_bus_id_school_id_fkey"
      columns: ["bus_id","school_id"]
isOneToOne: false
      referencedRelation: "buses"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "live_positions_trip_id_school_id_fkey"
      columns: ["trip_id","school_id"]
isOneToOne: false
      referencedRelation: "trips"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"notification_preferences": {
                  Row: {
                    "boarding_messages_on": boolean,"bus_near_minutes": number,"bus_near_on": boolean,"evening_on": boolean,"evening_time": string,"morning_on": boolean,"morning_time": string,"riding_days": number,"school_id": string,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "boarding_messages_on"?: boolean,"bus_near_minutes"?: number,"bus_near_on"?: boolean,"evening_on"?: boolean,"evening_time"?: string,"morning_on"?: boolean,"morning_time"?: string,"riding_days"?: number,"school_id": string,"updated_at"?: string,"user_id": string
                  }
                  Update: {
                    "boarding_messages_on"?: boolean,"bus_near_minutes"?: number,"bus_near_on"?: boolean,"evening_on"?: boolean,"evening_time"?: string,"morning_on"?: boolean,"morning_time"?: string,"riding_days"?: number,"school_id"?: string,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "notification_preferences_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "notification_preferences_user_id_fkey"
      columns: ["user_id"]
isOneToOne: true
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"places": {
                  Row: {
                    "id": number,"kind": string,"location": unknown,"name": string,"osm_id": string,"school_id": string,"search_key": string
                  }
                  ComputedFields: never
                  Insert: {
                    "id"?: never,"kind": string,"location": unknown,"name": string,"osm_id": string,"school_id": string,"search_key": string
                  }
                  Update: {
                    "id"?: never,"kind"?: string,"location"?: unknown,"name"?: string,"osm_id"?: string,"school_id"?: string,"search_key"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "places_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"department": string | null,"department_id": string | null,"email": string,"full_name": string,"id": string,"join_decline_note": string | null,"join_declined_at": string | null,"join_declined_school": string | null,"join_requested_at": string | null,"matricule": string | null,"phone": string | null,"program": string | null,"program_id": string | null,"role": Database["public"]['Enums']["user_role"],"school_id": string | null,"status": Database["public"]['Enums']["account_status"],"streak_opt_in": boolean,"streak_opt_in_at": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"department"?: string | null,"department_id"?: string | null,"email": string,"full_name"?: string,"id": string,"join_decline_note"?: string | null,"join_declined_at"?: string | null,"join_declined_school"?: string | null,"join_requested_at"?: string | null,"matricule"?: string | null,"phone"?: string | null,"program"?: string | null,"program_id"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string | null,"status"?: Database["public"]['Enums']["account_status"],"streak_opt_in"?: boolean,"streak_opt_in_at"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"department"?: string | null,"department_id"?: string | null,"email"?: string,"full_name"?: string,"id"?: string,"join_decline_note"?: string | null,"join_declined_at"?: string | null,"join_declined_school"?: string | null,"join_requested_at"?: string | null,"matricule"?: string | null,"phone"?: string | null,"program"?: string | null,"program_id"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string | null,"status"?: Database["public"]['Enums']["account_status"],"streak_opt_in"?: boolean,"streak_opt_in_at"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "profiles_department_id_school_id_fkey"
      columns: ["department_id","school_id"]
isOneToOne: false
      referencedRelation: "departments"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "profiles_program_id_school_id_fkey"
      columns: ["program_id","school_id"]
isOneToOne: false
      referencedRelation: "programs"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "profiles_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"programs": {
                  Row: {
                    "created_at": string,"id": string,"name": string,"school_id": string,"sort_order": number
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"id"?: string,"name": string,"school_id": string,"sort_order"?: number
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"name"?: string,"school_id"?: string,"sort_order"?: number
                  }
                  Relationships: [
                    {
      foreignKeyName: "programs_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"scans": {
                  Row: {
                    "accuracy_m": number | null,"client_id": string | null,"id": string,"location": unknown,"scanned_at": string,"scanned_by": string,"school_id": string,"stop_id": string | null,"student_id": string,"subscription_id": string,"trip_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "accuracy_m"?: number | null,"client_id"?: string | null,"id"?: string,"location"?: unknown,"scanned_at"?: string,"scanned_by": string,"school_id": string,"stop_id"?: string | null,"student_id": string,"subscription_id": string,"trip_id": string
                  }
                  Update: {
                    "accuracy_m"?: number | null,"client_id"?: string | null,"id"?: string,"location"?: unknown,"scanned_at"?: string,"scanned_by"?: string,"school_id"?: string,"stop_id"?: string | null,"student_id"?: string,"subscription_id"?: string,"trip_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "scans_scanned_by_school_id_fkey"
      columns: ["scanned_by","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "scans_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "scans_stop_id_school_id_fkey"
      columns: ["stop_id","school_id"]
isOneToOne: false
      referencedRelation: "stops"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "scans_student_id_school_id_fkey"
      columns: ["student_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "scans_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "scans_trip_id_school_id_fkey"
      columns: ["trip_id","school_id"]
isOneToOne: false
      referencedRelation: "trips"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"school_domains": {
                  Row: {
                    "created_at": string,"domain": string,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"domain": string,"school_id": string
                  }
                  Update: {
                    "created_at"?: string,"domain"?: string,"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_domains_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"schools": {
                  Row: {
                    "about": string | null,"accepts_open_signup": boolean,"address": string | null,"city": string | null,"contact_email": string | null,"country": string | null,"created_at": string,"id": string,"logo_path": string | null,"name": string,"open_signup_domains": (string)[],"phone": string | null,"public_listing": boolean,"short_name": string | null,"status": string,"terms_accepted_at": string | null,"terms_accepted_by": string | null,"terms_version": string | null,"timezone": string,"website": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "about"?: string | null,"accepts_open_signup"?: boolean,"address"?: string | null,"city"?: string | null,"contact_email"?: string | null,"country"?: string | null,"created_at"?: string,"id"?: string,"logo_path"?: string | null,"name": string,"open_signup_domains"?: (string)[],"phone"?: string | null,"public_listing"?: boolean,"short_name"?: string | null,"status"?: string,"terms_accepted_at"?: string | null,"terms_accepted_by"?: string | null,"terms_version"?: string | null,"timezone"?: string,"website"?: string | null
                  }
                  Update: {
                    "about"?: string | null,"accepts_open_signup"?: boolean,"address"?: string | null,"city"?: string | null,"contact_email"?: string | null,"country"?: string | null,"created_at"?: string,"id"?: string,"logo_path"?: string | null,"name"?: string,"open_signup_domains"?: (string)[],"phone"?: string | null,"public_listing"?: boolean,"short_name"?: string | null,"status"?: string,"terms_accepted_at"?: string | null,"terms_accepted_by"?: string | null,"terms_version"?: string | null,"timezone"?: string,"website"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"semesters": {
                  Row: {
                    "created_at": string,"created_by": string | null,"end_date": string,"id": string,"name": Database["public"]['Enums']["semester_name"],"school_id": string,"start_date": string,"year": number
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"created_by"?: string | null,"end_date": string,"id"?: string,"name": Database["public"]['Enums']["semester_name"],"school_id": string,"start_date": string,"year": number
                  }
                  Update: {
                    "created_at"?: string,"created_by"?: string | null,"end_date"?: string,"id"?: string,"name"?: Database["public"]['Enums']["semester_name"],"school_id"?: string,"start_date"?: string,"year"?: number
                  }
                  Relationships: [
                    {
      foreignKeyName: "semesters_created_by_fkey"
      columns: ["created_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "semesters_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_invites": {
                  Row: {
                    "created_at": string,"email": string,"expires_at": string,"invited_by": string | null,"role": Database["public"]['Enums']["user_role"],"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"email": string,"expires_at"?: string,"invited_by"?: string | null,"role": Database["public"]['Enums']["user_role"],"school_id": string
                  }
                  Update: {
                    "created_at"?: string,"email"?: string,"expires_at"?: string,"invited_by"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "staff_invites_invited_by_fkey"
      columns: ["invited_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "staff_invites_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"stops": {
                  Row: {
                    "active": boolean,"created_at": string,"created_by": string | null,"id": string,"location": unknown,"name": string,"photo_path": string | null,"school_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "active"?: boolean,"created_at"?: string,"created_by"?: string | null,"id"?: string,"location": unknown,"name": string,"photo_path"?: string | null,"school_id": string,"updated_at"?: string
                  }
                  Update: {
                    "active"?: boolean,"created_at"?: string,"created_by"?: string | null,"id"?: string,"location"?: unknown,"name"?: string,"photo_path"?: string | null,"school_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "stops_created_by_fkey"
      columns: ["created_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "stops_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"student_areas": {
                  Row: {
                    "area": unknown,"label": string,"school_id": string,"source": string,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "area": unknown,"label": string,"school_id": string,"source": string,"updated_at"?: string,"user_id": string
                  }
                  Update: {
                    "area"?: unknown,"label"?: string,"school_id"?: string,"source"?: string,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "student_areas_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "student_areas_user_id_fkey"
      columns: ["user_id"]
isOneToOne: true
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"subscription_events": {
                  Row: {
                    "action": string,"actor_id": string | null,"created_at": string,"id": number,"note": string | null,"school_id": string,"student_id": string,"subscription_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "action": string,"actor_id"?: string | null,"created_at"?: string,"id"?: never,"note"?: string | null,"school_id": string,"student_id": string,"subscription_id": string
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string | null,"created_at"?: string,"id"?: never,"note"?: string | null,"school_id"?: string,"student_id"?: string,"subscription_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "subscription_events_actor_id_fkey"
      columns: ["actor_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscription_events_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscription_events_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"subscriptions": {
                  Row: {
                    "created_at": string,"id": string,"proof_path": string | null,"review_note": string | null,"reviewed_at": string | null,"reviewed_by": string | null,"school_id": string,"semester_id": string,"status": Database["public"]['Enums']["subscription_status"],"stop_id": string,"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"id"?: string,"proof_path"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id": string,"semester_id": string,"status"?: Database["public"]['Enums']["subscription_status"],"stop_id": string,"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"proof_path"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id"?: string,"semester_id"?: string,"status"?: Database["public"]['Enums']["subscription_status"],"stop_id"?: string,"student_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "subscriptions_reviewed_by_fkey"
      columns: ["reviewed_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscriptions_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscriptions_semester_id_school_id_fkey"
      columns: ["semester_id","school_id"]
isOneToOne: false
      referencedRelation: "semesters"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "subscriptions_stop_id_school_id_fkey"
      columns: ["stop_id","school_id"]
isOneToOne: false
      referencedRelation: "stops"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "subscriptions_student_id_school_id_fkey"
      columns: ["student_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"trip_positions": {
                  Row: {
                    "id": number,"location": unknown,"recorded_at": string,"school_id": string,"speed_mps": number | null,"trip_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "id"?: never,"location": unknown,"recorded_at"?: string,"school_id": string,"speed_mps"?: number | null,"trip_id": string
                  }
                  Update: {
                    "id"?: never,"location"?: unknown,"recorded_at"?: string,"school_id"?: string,"speed_mps"?: number | null,"trip_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "trip_positions_trip_id_school_id_fkey"
      columns: ["trip_id","school_id"]
isOneToOne: false
      referencedRelation: "trips"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"trips": {
                  Row: {
                    "archived_at": string | null,"bus_id": string,"created_at": string,"direction": Database["public"]['Enums']["trip_direction"],"driver_id": string | null,"ended_at": string | null,"id": string,"scheduled_start": string,"school_id": string,"started_at": string | null,"started_by": string | null,"status": Database["public"]['Enums']["trip_status"]
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"bus_id": string,"created_at"?: string,"direction": Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"scheduled_start": string,"school_id": string,"started_at"?: string | null,"started_by"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
                  }
                  Update: {
                    "archived_at"?: string | null,"bus_id"?: string,"created_at"?: string,"direction"?: Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"scheduled_start"?: string,"school_id"?: string,"started_at"?: string | null,"started_by"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
                  }
                  Relationships: [
                    {
      foreignKeyName: "trips_bus_id_school_id_fkey"
      columns: ["bus_id","school_id"]
isOneToOne: false
      referencedRelation: "buses"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "trips_driver_id_school_id_fkey"
      columns: ["driver_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "trips_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "trips_started_by_fkey"
      columns: ["started_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "admin_accept_school_terms":
{ Args: { "p_version": string }; Returns: undefined
                           },
"admin_area_counts":
{ Args: Record<PropertyKey, never>; Returns: {
              "lat": number,"lng": number,"students": number
            }[]
                           },
"admin_boardings_by_day":
{ Args: { "p_days"?: number }; Returns: {
              "boardings": number,"day": string
            }[]
                           },
"admin_cancel_invite":
{ Args: { "p_email": string }; Returns: undefined
                           },
"admin_cancel_trip":
{ Args: { "p_reason"?: string,"p_trip_id": string }; Returns: undefined
                           },
"admin_decline_member":
{ Args: { "p_reason"?: string,"p_user_id": string }; Returns: undefined
                           },
"admin_desire_lines":
{ Args: Record<PropertyKey, never>; Returns: {
              "distance_m": number,"lat": number,"lng": number,"stop_id": string,"students": number
            }[]
                           },
"admin_invite_staff":
{ Args: { "p_email": string,"p_role": Database["public"]['Enums']["user_role"] }; Returns: string
                           },
"admin_nearer_stops":
{ Args: Record<PropertyKey, never>; Returns: {
              "from_stop": string,"saved_m": number,"students": number,"to_stop": string
            }[]
                           },
"admin_overdue_trips":
{ Args: Record<PropertyKey, never>; Returns: {
              "last_position_at": string,"reason": string,"started_at": string,"trip_id": string
            }[]
                           },
"admin_refresh_stop_loads":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"admin_reinstate_subscription":
{ Args: { "p_note"?: string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_review_subscription":
{ Args: { "p_decision": string,"p_note"?: string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_revoke_subscription":
{ Args: { "p_note": string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_set_school_logo":
{ Args: { "p_path": string }; Returns: undefined
                           },
"admin_set_trip_archived":
{ Args: { "p_archived": boolean,"p_trip_id": string }; Returns: undefined
                           },
"admin_set_user_role":
{ Args: { "p_role": Database["public"]['Enums']["user_role"],"p_user_id": string }; Returns: undefined
                           },
"admin_set_user_status":
{ Args: { "p_status": Database["public"]['Enums']["account_status"],"p_user_id": string }; Returns: undefined
                           },
"admin_stop_loads":
{ Args: { "p_days"?: number }; Returns: {
              "boardings": number,"departures": number,"last_day": string,"load": number,"peak": number,"peak_load": number,"per_departure": number,"refreshed_at": string,"stop_id": string
            }[]
                           },
"admin_stop_proximity":
{ Args: Record<PropertyKey, never>; Returns: {
              "median_m": number,"over_2k": number,"stop_id": string,"subscribers": number,"to_1k": number,"to_2k": number,"under_500": number,"with_area": number
            }[]
                           },
"admin_stop_suggestions":
{ Args: Record<PropertyKey, never>; Returns: {
              "kind": string,"lat": number,"lng": number,"metres": number,"other_stop_id": string,"place_name": string,"stop_id": string,"students": number
            }[]
                           },
"admin_stop_usage":
{ Args: Record<PropertyKey, never>; Returns: {
              "pending": number,"stop_id": string,"students": number
            }[]
                           },
"admin_update_school_profile":
{ Args: { "p_about": string,"p_accepts_open_signup": boolean,"p_address": string,"p_city": string,"p_contact_email": string,"p_country": string,"p_name": string,"p_open_signup_domains"?: (string)[],"p_phone": string,"p_public_listing": boolean,"p_short_name": string,"p_website": string }; Returns: undefined
                           },
"admin_verify_member":
{ Args: { "p_user_id": string }; Returns: undefined
                           },
"can_follow_buses":
{ Args: Record<PropertyKey, never>; Returns: boolean
                           },
"claim_notifications":
{ Args: { "p_limit"?: number }; Returns: {
              "id": number,"kind": string,"ref_id": string,"tokens": Json
            }[]
                           },
"clear_my_area":
{ Args: Record<PropertyKey, never>; Returns: undefined
                           },
"complete_notification":
{ Args: { "p_error"?: string,"p_id": number }; Returns: undefined
                           },
"custom_access_token_hook":
{ Args: { "event": Json }; Returns: Json
                           },
"drop_device_token":
{ Args: { "p_token": string }; Returns: undefined
                           },
"end_trip":
{ Args: { "p_trip_id": string }; Returns: undefined
                           },
"get_my_qr_secret":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"import_places":
{ Args: { "p_places": Json,"p_school_id": string }; Returns: number
                           },
"list_open_schools":
{ Args: Record<PropertyKey, never>; Returns: {
              "city": string,"country": string,"id": string,"logo_path": string,"name": string,"short_name": string
            }[]
                           },
"my_area":
{ Args: Record<PropertyKey, never>; Returns: {
              "label": string,"lat": number,"lng": number,"source": string,"updated_at": string
            }[]
                           },
"my_join_request":
{ Args: Record<PropertyKey, never>; Returns: {
              "decline_note": string,"declined_at": string,"declined_school_name": string,"requested_at": string,"school_id": string,"school_logo_path": string,"school_name": string
            }[]
                           },
"my_notification_preferences":
{ Args: Record<PropertyKey, never>; Returns: {
              "boarding_messages_on": boolean,"bus_near_minutes": number,"bus_near_on": boolean,"evening_on": boolean,"evening_time": string,"morning_on": boolean,"morning_time": string,"riding_days": number
            }[]
                           },
"my_ride_days":
{ Args: { "p_semester_id": string }; Returns: {
              "day": string,"state": string
            }[]
                           },
"my_streak":
{ Args: { "p_semester_id": string }; Returns: {
              "best_streak": number,"current_streak": number,"rides": number
            }[]
                           },
"place_import_box":
{ Args: { "p_school_id": string }; Returns: {
              "east": number,"north": number,"south": number,"west": number
            }[]
                           },
"public_schools":
{ Args: Record<PropertyKey, never>; Returns: {
              "city": string,"country": string,"id": string,"logo_path": string,"name": string,"short_name": string
            }[]
                           },
"publish_position":
{ Args: { "p_accuracy_m"?: number,"p_heading_deg"?: number,"p_lat": number,"p_lng": number,"p_speed_mps"?: number,"p_trip_id": string }; Returns: boolean
                           },
"record_qr_scan":
{ Args: { "p_accuracy"?: number,"p_client_id"?: string,"p_code": string,"p_lat"?: number,"p_lng"?: number,"p_scanned_at"?: string,"p_stop_id"?: string,"p_trip_id": string }; Returns: Json
                           },
"register_device_token":
{ Args: { "p_locale"?: string,"p_platform": string,"p_token": string }; Returns: undefined
                           },
"request_school":
{ Args: { "p_school_id": string }; Returns: undefined
                           },
"rotate_my_qr_secret":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"school_leaderboard":
{ Args: { "p_limit"?: number,"p_semester_id": string }; Returns: {
              "avatar_url": string,"current_streak": number,"display_name": string,"is_me": boolean,"rank": number,"rides": number
            }[]
                           },
"search_places":
{ Args: { "p_limit"?: number,"p_query": string }; Returns: {
              "kind": string,"label": string,"lat": number,"lng": number
            }[]
                           },
"set_my_area":
{ Args: { "p_label": string,"p_lat": number,"p_lng": number,"p_source": string }; Returns: undefined
                           },
"set_notification_preferences":
{ Args: { "p_boarding_messages_on": boolean,"p_bus_near_minutes": number,"p_bus_near_on": boolean,"p_evening_on": boolean,"p_evening_time": string,"p_morning_on": boolean,"p_morning_time": string,"p_riding_days": number }; Returns: undefined
                           },
"set_streak_opt_in":
{ Args: { "p_on": boolean }; Returns: undefined
                           },
"staff_day_keys":
{ Args: Record<PropertyKey, never>; Returns: {
              "avatar_url": string,"day": string,"day_key": string,"full_name": string,"matricule": string,"stop_id": string,"student_id": string
            }[]
                           },
"start_trip":
{ Args: { "p_trip_id": string }; Returns: undefined
                           },
"submit_interest":
{ Args: { "p_email": string,"p_kind": string,"p_locale"?: string,"p_message"?: string,"p_name"?: string,"p_organisation"?: string,"p_trap"?: string }; Returns: string
                           },
"trip_manifest":
{ Args: { "p_trip_id": string }; Returns: {
              "avatar_url": string,"full_name": string,"matricule": string,"scan_id": string,"scanned_at": string,"stop_id": string,"student_id": string
            }[]
                           },
"unregister_device_token":
{ Args: { "p_token": string }; Returns: undefined
                           }
          }
          Enums: {
            "account_status": "pending"|"verified"|"suspended","semester_name": "fall"|"spring"|"summer","subscription_status": "pending"|"approved"|"rejected"|"expired"|"revoked","trip_direction": "inbound"|"outbound","trip_status": "scheduled"|"active"|"completed"|"cancelled","user_role": "student"|"staff"|"admin"
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            "account_status": ["pending", "verified", "suspended"],"semester_name": ["fall", "spring", "summer"],"subscription_status": ["pending", "approved", "rejected", "expired", "revoked"],"trip_direction": ["inbound", "outbound"],"trip_status": ["scheduled", "active", "completed", "cancelled"],"user_role": ["student", "staff", "admin"]
          }
        }
} as const
