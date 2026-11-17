
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
                },"busin_charges": {
                  Row: {
                    "amount_xaf": number,"billing_period": string | null,"created_at": string,"id": string,"school_id": string,"subscription_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"billing_period"?: string | null,"created_at"?: string,"id"?: string,"school_id": string,"subscription_id": string
                  }
                  Update: {
                    "amount_xaf"?: number,"billing_period"?: string | null,"created_at"?: string,"id"?: string,"school_id"?: string,"subscription_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "busin_charges_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "busin_charges_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"busin_invoices": {
                  Row: {
                    "amount_xaf": number,"due_date": string,"id": string,"issued_at": string,"month": string,"number": string,"paid_at": string | null,"school_id": string,"status": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"due_date": string,"id"?: string,"issued_at"?: string,"month": string,"number": string,"paid_at"?: string | null,"school_id": string,"status"?: string
                  }
                  Update: {
                    "amount_xaf"?: number,"due_date"?: string,"id"?: string,"issued_at"?: string,"month"?: string,"number"?: string,"paid_at"?: string | null,"school_id"?: string,"status"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "busin_invoices_school_id_fkey"
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
                },"installment_receipts": {
                  Row: {
                    "decided_at": string | null,"decided_by": string | null,"decision": string | null,"id": string,"installment_id": string,"note": string | null,"payment_id": string | null,"proof_path": string | null,"school_id": string,"sent_at": string,"seq": number,"student_id": string,"subscription_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "decided_at"?: string | null,"decided_by"?: string | null,"decision"?: string | null,"id"?: string,"installment_id": string,"note"?: string | null,"payment_id"?: string | null,"proof_path"?: string | null,"school_id": string,"sent_at"?: string,"seq": number,"student_id": string,"subscription_id": string
                  }
                  Update: {
                    "decided_at"?: string | null,"decided_by"?: string | null,"decision"?: string | null,"id"?: string,"installment_id"?: string,"note"?: string | null,"payment_id"?: string | null,"proof_path"?: string | null,"school_id"?: string,"sent_at"?: string,"seq"?: number,"student_id"?: string,"subscription_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "installment_receipts_decided_by_fkey"
      columns: ["decided_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "installment_receipts_installment_id_fkey"
      columns: ["installment_id"]
isOneToOne: false
      referencedRelation: "subscription_installments"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "installment_receipts_payment_id_fkey"
      columns: ["payment_id"]
isOneToOne: false
      referencedRelation: "payments"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "installment_receipts_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "installment_receipts_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"interest_requests": {
                  Row: {
                    "created_at": string,"email": string,"handled_at": string | null,"id": string,"kind": string,"locale": string,"message": string | null,"name": string | null,"note": string | null,"organisation": string | null,"school_id": string | null,"status": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"email": string,"handled_at"?: string | null,"id"?: string,"kind": string,"locale"?: string,"message"?: string | null,"name"?: string | null,"note"?: string | null,"organisation"?: string | null,"school_id"?: string | null,"status"?: string
                  }
                  Update: {
                    "created_at"?: string,"email"?: string,"handled_at"?: string | null,"id"?: string,"kind"?: string,"locale"?: string,"message"?: string | null,"name"?: string | null,"note"?: string | null,"organisation"?: string | null,"school_id"?: string | null,"status"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "interest_requests_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
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
                },"payments": {
                  Row: {
                    "amount_xaf": number,"checks": number,"completed_at": string | null,"created_at": string,"currency": string,"est_cost_xaf": number,"failure_code": string | null,"failure_message": string | null,"fee_xaf": number,"id": string,"installment_id": string | null,"invoice_id": string | null,"item_key": string,"last_checked_at": string | null,"outcome": string | null,"paid_by": string,"payer_masked": string,"provider": string,"provider_fee_xaf": number | null,"provider_txn": string | null,"purpose": string,"receipt_no": string | null,"school_id": string,"school_pays_costs": boolean,"status": string,"subscription_id": string | null,"total_xaf": number | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"checks"?: number,"completed_at"?: string | null,"created_at"?: string,"currency"?: string,"est_cost_xaf"?: number,"failure_code"?: string | null,"failure_message"?: string | null,"fee_xaf": number,"id"?: string,"installment_id"?: string | null,"invoice_id"?: string | null,"item_key": string,"last_checked_at"?: string | null,"outcome"?: string | null,"paid_by": string,"payer_masked": string,"provider": string,"provider_fee_xaf"?: number | null,"provider_txn"?: string | null,"purpose": string,"receipt_no"?: string | null,"school_id": string,"school_pays_costs"?: boolean,"status"?: string,"subscription_id"?: string | null,"total_xaf"?: never,"updated_at"?: string
                  }
                  Update: {
                    "amount_xaf"?: number,"checks"?: number,"completed_at"?: string | null,"created_at"?: string,"currency"?: string,"est_cost_xaf"?: number,"failure_code"?: string | null,"failure_message"?: string | null,"fee_xaf"?: number,"id"?: string,"installment_id"?: string | null,"invoice_id"?: string | null,"item_key"?: string,"last_checked_at"?: string | null,"outcome"?: string | null,"paid_by"?: string,"payer_masked"?: string,"provider"?: string,"provider_fee_xaf"?: number | null,"provider_txn"?: string | null,"purpose"?: string,"receipt_no"?: string | null,"school_id"?: string,"school_pays_costs"?: boolean,"status"?: string,"subscription_id"?: string | null,"total_xaf"?: never,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "payments_installment_id_fkey"
      columns: ["installment_id"]
isOneToOne: false
      referencedRelation: "subscription_installments"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "payments_invoice_id_fkey"
      columns: ["invoice_id"]
isOneToOne: false
      referencedRelation: "busin_invoices"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "payments_paid_by_fkey"
      columns: ["paid_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "payments_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "payments_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"payouts": {
                  Row: {
                    "account_id": string,"amount_xaf": number,"completed_at": string | null,"created_at": string,"failure_code": string | null,"id": string,"phone_masked": string,"provider": string,"provider_txn": string | null,"school_id": string,"status": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "account_id": string,"amount_xaf": number,"completed_at"?: string | null,"created_at"?: string,"failure_code"?: string | null,"id"?: string,"phone_masked": string,"provider": string,"provider_txn"?: string | null,"school_id": string,"status"?: string,"updated_at"?: string
                  }
                  Update: {
                    "account_id"?: string,"amount_xaf"?: number,"completed_at"?: string | null,"created_at"?: string,"failure_code"?: string | null,"id"?: string,"phone_masked"?: string,"provider"?: string,"provider_txn"?: string | null,"school_id"?: string,"status"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "payouts_account_id_fkey"
      columns: ["account_id"]
isOneToOne: false
      referencedRelation: "school_payout_accounts"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "payouts_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
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
                },"platform_audit": {
                  Row: {
                    "action": string,"actor_id": string,"created_at": string,"details": NonNullable<Json>,"id": number,"school_id": string | null,"target_id": string | null,"target_type": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "action": string,"actor_id": string,"created_at"?: string,"details"?: NonNullable<Json>,"id"?: never,"school_id"?: string | null,"target_id"?: string | null,"target_type"?: string | null
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string,"created_at"?: string,"details"?: NonNullable<Json>,"id"?: never,"school_id"?: string | null,"target_id"?: string | null,"target_type"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "platform_audit_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"platform_outreach": {
                  Row: {
                    "channel": string,"created_at": string,"created_by": string,"follow_up_done_at": string | null,"follow_up_on": string | null,"id": string,"note": string | null,"notice_id": string | null,"school_id": string,"signals": (string)[],"snooze_until": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "channel": string,"created_at"?: string,"created_by": string,"follow_up_done_at"?: string | null,"follow_up_on"?: string | null,"id"?: string,"note"?: string | null,"notice_id"?: string | null,"school_id": string,"signals"?: (string)[],"snooze_until"?: string | null
                  }
                  Update: {
                    "channel"?: string,"created_at"?: string,"created_by"?: string,"follow_up_done_at"?: string | null,"follow_up_on"?: string | null,"id"?: string,"note"?: string | null,"notice_id"?: string | null,"school_id"?: string,"signals"?: (string)[],"snooze_until"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "platform_outreach_notice_id_fkey"
      columns: ["notice_id"]
isOneToOne: false
      referencedRelation: "school_notices"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "platform_outreach_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"deleted_at": string | null,"deletion_by": string | null,"deletion_due_at": string | null,"deletion_requested_at": string | null,"department": string | null,"department_id": string | null,"email": string,"full_name": string,"id": string,"join_decline_note": string | null,"join_declined_at": string | null,"join_declined_school": string | null,"join_requested_at": string | null,"matricule": string | null,"payment_preference": string | null,"phone": string | null,"program": string | null,"program_id": string | null,"role": Database["public"]['Enums']["user_role"],"school_id": string | null,"staff_decline_note": string | null,"staff_declined_at": string | null,"staff_declined_school": string | null,"staff_request_school": string | null,"staff_requested_at": string | null,"status": Database["public"]['Enums']["account_status"],"streak_opt_in": boolean,"streak_opt_in_at": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"deletion_by"?: string | null,"deletion_due_at"?: string | null,"deletion_requested_at"?: string | null,"department"?: string | null,"department_id"?: string | null,"email": string,"full_name"?: string,"id": string,"join_decline_note"?: string | null,"join_declined_at"?: string | null,"join_declined_school"?: string | null,"join_requested_at"?: string | null,"matricule"?: string | null,"payment_preference"?: string | null,"phone"?: string | null,"program"?: string | null,"program_id"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string | null,"staff_decline_note"?: string | null,"staff_declined_at"?: string | null,"staff_declined_school"?: string | null,"staff_request_school"?: string | null,"staff_requested_at"?: string | null,"status"?: Database["public"]['Enums']["account_status"],"streak_opt_in"?: boolean,"streak_opt_in_at"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"deletion_by"?: string | null,"deletion_due_at"?: string | null,"deletion_requested_at"?: string | null,"department"?: string | null,"department_id"?: string | null,"email"?: string,"full_name"?: string,"id"?: string,"join_decline_note"?: string | null,"join_declined_at"?: string | null,"join_declined_school"?: string | null,"join_requested_at"?: string | null,"matricule"?: string | null,"payment_preference"?: string | null,"phone"?: string | null,"program"?: string | null,"program_id"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string | null,"staff_decline_note"?: string | null,"staff_declined_at"?: string | null,"staff_declined_school"?: string | null,"staff_request_school"?: string | null,"staff_requested_at"?: string | null,"status"?: Database["public"]['Enums']["account_status"],"streak_opt_in"?: boolean,"streak_opt_in_at"?: string | null,"updated_at"?: string
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
                },"refunds": {
                  Row: {
                    "amount_xaf": number,"completed_at": string | null,"decided_at": string | null,"decided_by": string | null,"decision_note": string | null,"failure_code": string | null,"fee_xaf": number,"id": string,"kind": string,"payment_id": string,"provider_txn": string | null,"reason": string | null,"receipt_no": string | null,"requested_at": string,"requested_by": string | null,"school_id": string,"status": string,"student_id": string,"total_xaf": number | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"completed_at"?: string | null,"decided_at"?: string | null,"decided_by"?: string | null,"decision_note"?: string | null,"failure_code"?: string | null,"fee_xaf"?: number,"id"?: string,"kind": string,"payment_id": string,"provider_txn"?: string | null,"reason"?: string | null,"receipt_no"?: string | null,"requested_at"?: string,"requested_by"?: string | null,"school_id": string,"status"?: string,"student_id": string,"total_xaf"?: never,"updated_at"?: string
                  }
                  Update: {
                    "amount_xaf"?: number,"completed_at"?: string | null,"decided_at"?: string | null,"decided_by"?: string | null,"decision_note"?: string | null,"failure_code"?: string | null,"fee_xaf"?: number,"id"?: string,"kind"?: string,"payment_id"?: string,"provider_txn"?: string | null,"reason"?: string | null,"receipt_no"?: string | null,"requested_at"?: string,"requested_by"?: string | null,"school_id"?: string,"status"?: string,"student_id"?: string,"total_xaf"?: never,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "refunds_decided_by_fkey"
      columns: ["decided_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "refunds_payment_id_fkey"
      columns: ["payment_id"]
isOneToOne: false
      referencedRelation: "payments"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "refunds_requested_by_fkey"
      columns: ["requested_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "refunds_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "refunds_student_id_fkey"
      columns: ["student_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"route_stops": {
                  Row: {
                    "position": number,"route_id": string,"school_id": string,"stop_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "position": number,"route_id": string,"school_id": string,"stop_id": string
                  }
                  Update: {
                    "position"?: number,"route_id"?: string,"school_id"?: string,"stop_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "route_stops_route_id_school_id_fkey"
      columns: ["route_id","school_id"]
isOneToOne: false
      referencedRelation: "routes"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "route_stops_stop_id_school_id_fkey"
      columns: ["stop_id","school_id"]
isOneToOne: false
      referencedRelation: "stops"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"routes": {
                  Row: {
                    "computed_at": string | null,"created_at": string,"distance_m": number | null,"drawn_hash": string | null,"duration_s": number | null,"geometry": unknown,"id": string,"legs": Json | null,"name": string,"school_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "computed_at"?: string | null,"created_at"?: string,"distance_m"?: number | null,"drawn_hash"?: string | null,"duration_s"?: number | null,"geometry"?: unknown,"id"?: string,"legs"?: Json | null,"name"?: string,"school_id": string,"updated_at"?: string
                  }
                  Update: {
                    "computed_at"?: string | null,"created_at"?: string,"distance_m"?: number | null,"drawn_hash"?: string | null,"duration_s"?: number | null,"geometry"?: unknown,"id"?: string,"legs"?: Json | null,"name"?: string,"school_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "routes_school_id_fkey"
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
                },"school_health_daily": {
                  Row: {
                    "day": string,"level": number,"school_id": string,"score": number,"signals": NonNullable<Json>
                  }
                  ComputedFields: never
                  Insert: {
                    "day": string,"level": number,"school_id": string,"score": number,"signals"?: NonNullable<Json>
                  }
                  Update: {
                    "day"?: string,"level"?: number,"school_id"?: string,"score"?: number,"signals"?: NonNullable<Json>
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_health_daily_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"school_ledger": {
                  Row: {
                    "amount_xaf": number,"available_at": string,"charge_id": string | null,"created_at": string,"id": number,"invoice_id": string | null,"kind": string,"note": string | null,"payment_id": string | null,"payout_id": string | null,"refund_id": string | null,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"available_at"?: string,"charge_id"?: string | null,"created_at"?: string,"id"?: never,"invoice_id"?: string | null,"kind": string,"note"?: string | null,"payment_id"?: string | null,"payout_id"?: string | null,"refund_id"?: string | null,"school_id": string
                  }
                  Update: {
                    "amount_xaf"?: number,"available_at"?: string,"charge_id"?: string | null,"created_at"?: string,"id"?: never,"invoice_id"?: string | null,"kind"?: string,"note"?: string | null,"payment_id"?: string | null,"payout_id"?: string | null,"refund_id"?: string | null,"school_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_ledger_charge_id_fkey"
      columns: ["charge_id"]
isOneToOne: false
      referencedRelation: "busin_charges"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_ledger_invoice_id_fkey"
      columns: ["invoice_id"]
isOneToOne: false
      referencedRelation: "busin_invoices"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_ledger_payment_id_fkey"
      columns: ["payment_id"]
isOneToOne: false
      referencedRelation: "payments"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_ledger_payout_id_fkey"
      columns: ["payout_id"]
isOneToOne: false
      referencedRelation: "payouts"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_ledger_refund_id_fkey"
      columns: ["refund_id"]
isOneToOne: false
      referencedRelation: "refunds"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_ledger_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"school_notices": {
                  Row: {
                    "body": string,"body_doc": Json | null,"created_at": string,"created_by": string,"dismissed_at": string | null,"dismissed_by": string | null,"expires_at": string,"id": string,"link_path": string | null,"school_id": string,"signals": (string)[]
                  }
                  ComputedFields: never
                  Insert: {
                    "body": string,"body_doc"?: Json | null,"created_at"?: string,"created_by": string,"dismissed_at"?: string | null,"dismissed_by"?: string | null,"expires_at"?: string,"id"?: string,"link_path"?: string | null,"school_id": string,"signals"?: (string)[]
                  }
                  Update: {
                    "body"?: string,"body_doc"?: Json | null,"created_at"?: string,"created_by"?: string,"dismissed_at"?: string | null,"dismissed_by"?: string | null,"expires_at"?: string,"id"?: string,"link_path"?: string | null,"school_id"?: string,"signals"?: (string)[]
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_notices_dismissed_by_fkey"
      columns: ["dismissed_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_notices_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"school_payout_accounts": {
                  Row: {
                    "account_name": string | null,"confirmed_at": string | null,"confirmed_by": string | null,"id": string,"phone": string,"proposed_at": string,"proposed_by": string | null,"provider": string,"retired_at": string | null,"school_id": string,"status": string,"usable_from": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "account_name"?: string | null,"confirmed_at"?: string | null,"confirmed_by"?: string | null,"id"?: string,"phone": string,"proposed_at"?: string,"proposed_by"?: string | null,"provider": string,"retired_at"?: string | null,"school_id": string,"status"?: string,"usable_from"?: string | null
                  }
                  Update: {
                    "account_name"?: string | null,"confirmed_at"?: string | null,"confirmed_by"?: string | null,"id"?: string,"phone"?: string,"proposed_at"?: string,"proposed_by"?: string | null,"provider"?: string,"retired_at"?: string | null,"school_id"?: string,"status"?: string,"usable_from"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_payout_accounts_confirmed_by_fkey"
      columns: ["confirmed_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_payout_accounts_proposed_by_fkey"
      columns: ["proposed_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_payout_accounts_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"schools": {
                  Row: {
                    "about": string | null,"accepts_open_signup": boolean,"address": string | null,"allow_field_trips": boolean,"billing_period": string | null,"campus_location": unknown,"campus_name": string | null,"city": string | null,"contact_email": string | null,"country": string | null,"created_at": string,"currency": string,"fees_paid_by": string,"id": string,"installment_plan": string | null,"logo_path": string | null,"name": string,"open_signup_domains": (string)[],"phone": string | null,"phone_secondary": string | null,"price_xaf": number | null,"public_listing": boolean,"short_name": string | null,"status": string,"terms_accepted_at": string | null,"terms_accepted_by": string | null,"terms_version": string | null,"timezone": string,"website": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "about"?: string | null,"accepts_open_signup"?: boolean,"address"?: string | null,"allow_field_trips"?: boolean,"billing_period"?: string | null,"campus_location"?: unknown,"campus_name"?: string | null,"city"?: string | null,"contact_email"?: string | null,"country"?: string | null,"created_at"?: string,"currency"?: string,"fees_paid_by"?: string,"id"?: string,"installment_plan"?: string | null,"logo_path"?: string | null,"name": string,"open_signup_domains"?: (string)[],"phone"?: string | null,"phone_secondary"?: string | null,"price_xaf"?: number | null,"public_listing"?: boolean,"short_name"?: string | null,"status"?: string,"terms_accepted_at"?: string | null,"terms_accepted_by"?: string | null,"terms_version"?: string | null,"timezone"?: string,"website"?: string | null
                  }
                  Update: {
                    "about"?: string | null,"accepts_open_signup"?: boolean,"address"?: string | null,"allow_field_trips"?: boolean,"billing_period"?: string | null,"campus_location"?: unknown,"campus_name"?: string | null,"city"?: string | null,"contact_email"?: string | null,"country"?: string | null,"created_at"?: string,"currency"?: string,"fees_paid_by"?: string,"id"?: string,"installment_plan"?: string | null,"logo_path"?: string | null,"name"?: string,"open_signup_domains"?: (string)[],"phone"?: string | null,"phone_secondary"?: string | null,"price_xaf"?: number | null,"public_listing"?: boolean,"short_name"?: string | null,"status"?: string,"terms_accepted_at"?: string | null,"terms_accepted_by"?: string | null,"terms_version"?: string | null,"timezone"?: string,"website"?: string | null
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
                },"subscription_installments": {
                  Row: {
                    "amount_xaf": number,"created_at": string,"due_date": string,"id": string,"percent": number,"proof_path": string | null,"reminded_on": string | null,"review_note": string | null,"reviewed_at": string | null,"reviewed_by": string | null,"school_id": string,"seq": number,"status": string,"student_id": string,"submitted_at": string | null,"subscription_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf": number,"created_at"?: string,"due_date": string,"id"?: string,"percent": number,"proof_path"?: string | null,"reminded_on"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id": string,"seq": number,"status"?: string,"student_id": string,"submitted_at"?: string | null,"subscription_id": string
                  }
                  Update: {
                    "amount_xaf"?: number,"created_at"?: string,"due_date"?: string,"id"?: string,"percent"?: number,"proof_path"?: string | null,"reminded_on"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id"?: string,"seq"?: number,"status"?: string,"student_id"?: string,"submitted_at"?: string | null,"subscription_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "subscription_installments_reviewed_by_fkey"
      columns: ["reviewed_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscription_installments_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "subscription_installments_student_id_school_id_fkey"
      columns: ["student_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "subscription_installments_subscription_id_school_id_fkey"
      columns: ["subscription_id","school_id"]
isOneToOne: false
      referencedRelation: "subscriptions"
      referencedColumns: ["id","school_id"]
    }
                  ]
                },"subscriptions": {
                  Row: {
                    "amount_xaf": number | null,"billing_period": string | null,"charge_xaf": number | null,"created_at": string,"id": string,"installment_plan": string | null,"payment_method": string,"payment_mode": string,"period_end": string | null,"period_start": string | null,"proof_path": string | null,"review_note": string | null,"reviewed_at": string | null,"reviewed_by": string | null,"school_id": string,"semester_id": string,"status": Database["public"]['Enums']["subscription_status"],"stop_id": string,"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_xaf"?: number | null,"billing_period"?: string | null,"charge_xaf"?: number | null,"created_at"?: string,"id"?: string,"installment_plan"?: string | null,"payment_method"?: string,"payment_mode"?: string,"period_end"?: string | null,"period_start"?: string | null,"proof_path"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id": string,"semester_id": string,"status"?: Database["public"]['Enums']["subscription_status"],"stop_id": string,"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "amount_xaf"?: number | null,"billing_period"?: string | null,"charge_xaf"?: number | null,"created_at"?: string,"id"?: string,"installment_plan"?: string | null,"payment_method"?: string,"payment_mode"?: string,"period_end"?: string | null,"period_start"?: string | null,"proof_path"?: string | null,"review_note"?: string | null,"reviewed_at"?: string | null,"reviewed_by"?: string | null,"school_id"?: string,"semester_id"?: string,"status"?: Database["public"]['Enums']["subscription_status"],"stop_id"?: string,"student_id"?: string,"updated_at"?: string
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
                },"trip_position_leases": {
                  Row: {
                    "holder": string,"renewed_at": string,"school_id": string,"trip_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "holder": string,"renewed_at"?: string,"school_id": string,"trip_id": string
                  }
                  Update: {
                    "holder"?: string,"renewed_at"?: string,"school_id"?: string,"trip_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "trip_position_leases_holder_fkey"
      columns: ["holder"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "trip_position_leases_trip_id_school_id_fkey"
      columns: ["trip_id","school_id"]
isOneToOne: false
      referencedRelation: "trips"
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
                    "archived_at": string | null,"assistant_id": string | null,"bus_id": string,"created_at": string,"created_by": string | null,"direction": Database["public"]['Enums']["trip_direction"],"driver_id": string | null,"ended_at": string | null,"id": string,"origin": string,"scheduled_start": string,"school_id": string,"started_at": string | null,"started_by": string | null,"status": Database["public"]['Enums']["trip_status"]
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"assistant_id"?: string | null,"bus_id": string,"created_at"?: string,"created_by"?: string | null,"direction": Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"origin"?: string,"scheduled_start": string,"school_id": string,"started_at"?: string | null,"started_by"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
                  }
                  Update: {
                    "archived_at"?: string | null,"assistant_id"?: string | null,"bus_id"?: string,"created_at"?: string,"created_by"?: string | null,"direction"?: Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"origin"?: string,"scheduled_start"?: string,"school_id"?: string,"started_at"?: string | null,"started_by"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
                  }
                  Relationships: [
                    {
      foreignKeyName: "trips_assistant_fk"
      columns: ["assistant_id","school_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "trips_bus_id_school_id_fkey"
      columns: ["bus_id","school_id"]
isOneToOne: false
      referencedRelation: "buses"
      referencedColumns: ["id","school_id"]
    },{
      foreignKeyName: "trips_created_by_fkey"
      columns: ["created_by"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
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
"admin_confirm_payout_account":
{ Args: { "p_account": string }; Returns: undefined
                           },
"admin_decide_refund":
{ Args: { "p_amount"?: number,"p_approve": boolean,"p_note"?: string,"p_refund": string }; Returns: undefined
                           },
"admin_decline_member":
{ Args: { "p_reason"?: string,"p_user_id": string }; Returns: undefined
                           },
"admin_decline_payout_account":
{ Args: { "p_account": string }; Returns: undefined
                           },
"admin_delete_stop":
{ Args: { "p_stop_id": string }; Returns: undefined
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
"admin_payment_summary":
{ Args: { "p_months"?: number }; Returns: Json
                           },
"admin_propose_payout_account":
{ Args: { "p_account_name": string,"p_phone": string,"p_provider": string }; Returns: string
                           },
"admin_refresh_stop_loads":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"admin_refund_payment":
{ Args: { "p_amount": number,"p_payment": string,"p_reason": string }; Returns: string
                           },
"admin_reinstate_subscription":
{ Args: { "p_note"?: string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_review_installment":
{ Args: { "p_decision": string,"p_installment": string,"p_note"?: string }; Returns: undefined
                           },
"admin_review_staff_request":
{ Args: { "p_approve": boolean,"p_note"?: string,"p_user_id": string }; Returns: undefined
                           },
"admin_review_subscription":
{ Args: { "p_decision": string,"p_note"?: string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_revoke_subscription":
{ Args: { "p_note": string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_route_corridor":
{ Args: Record<PropertyKey, never>; Returns: {
              "has_route": boolean,"median_m": number,"over_2k": number,"subscribers": number,"to_1k": number,"to_2k": number,"under_500": number,"with_area": number
            }[]
                           },
"admin_save_route":
{ Args: { "p_stop_ids": (string)[] }; Returns: string
                           },
"admin_set_billing":
{ Args: { "p_period": string,"p_plan"?: string,"p_price": number }; Returns: undefined
                           },
"admin_set_campus":
{ Args: { "p_lat": number,"p_lng": number,"p_name": string }; Returns: undefined
                           },
"admin_set_fees_paid_by":
{ Args: { "p_who": string }; Returns: undefined
                           },
"admin_set_field_trips":
{ Args: { "p_allowed": boolean }; Returns: undefined
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
"admin_staff_requests":
{ Args: Record<PropertyKey, never>; Returns: {
              "avatar_url": string,"email": string,"full_name": string,"id": string,"live_subscription": boolean,"requested_at": string,"student_here": boolean
            }[]
                           },
"admin_stop_history":
{ Args: Record<PropertyKey, never>; Returns: {
              "boardings": number,"stop_id": string,"subscriptions": number
            }[]
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
              "insert_after": number,"kind": string,"lat": number,"lng": number,"metres": number,"other_stop_id": string,"place_name": string,"stop_id": string,"students": number
            }[]
                           },
"admin_stop_usage":
{ Args: Record<PropertyKey, never>; Returns: {
              "pending": number,"stop_id": string,"students": number
            }[]
                           },
"admin_update_school_profile":
{ Args: { "p_about": string,"p_accepts_open_signup": boolean,"p_address": string,"p_city": string,"p_contact_email": string,"p_country": string,"p_name": string,"p_open_signup_domains"?: (string)[],"p_phone": string,"p_phone_secondary"?: string,"p_public_listing": boolean,"p_short_name": string,"p_website": string }; Returns: undefined
                           },
"admin_verify_member":
{ Args: { "p_user_id": string }; Returns: undefined
                           },
"am_platform_admin":
{ Args: Record<PropertyKey, never>; Returns: boolean
                           },
"attach_subscription_proof":
{ Args: { "p_path": string,"p_subscription": string }; Returns: undefined
                           },
"can_follow_buses":
{ Args: Record<PropertyKey, never>; Returns: boolean
                           },
"cancel_account_deletion":
{ Args: Record<PropertyKey, never>; Returns: undefined
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
"dismiss_school_notice":
{ Args: { "p_notice_id": string }; Returns: undefined
                           },
"drop_device_token":
{ Args: { "p_token": string }; Returns: undefined
                           },
"due_account_deletions":
{ Args: Record<PropertyKey, never>; Returns: {
              "files": (string)[],"user_id": string
            }[]
                           },
"end_trip":
{ Args: { "p_trip_id": string }; Returns: undefined
                           },
"erase_account":
{ Args: { "p_user_id": string }; Returns: undefined
                           },
"field_trip_options":
{ Args: Record<PropertyKey, never>; Returns: Json
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
"list_staff_request_schools":
{ Args: Record<PropertyKey, never>; Returns: {
              "city": string,"country": string,"id": string,"logo_path": string,"name": string,"short_name": string
            }[]
                           },
"my_account_deletion":
{ Args: Record<PropertyKey, never>; Returns: {
              "due_at": string,"requested_at": string,"requested_by": string
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
"my_staff_request":
{ Args: Record<PropertyKey, never>; Returns: {
              "decline_note": string,"declined_at": string,"declined_school_name": string,"requested_at": string,"school_id": string,"school_logo_path": string,"school_name": string
            }[]
                           },
"my_streak":
{ Args: { "p_semester_id": string }; Returns: {
              "best_streak": number,"current_streak": number,"rides": number
            }[]
                           },
"my_trip_history":
{ Args: { "p_before": string,"p_limit"?: number }; Returns: {
              "boarded": number,"bus_id": string,"bus_label": string,"direction": Database["public"]['Enums']["trip_direction"],"ended_at": string,"id": string,"my_role": string,"origin": string,"scheduled_start": string,"started_at": string,"status": Database["public"]['Enums']["trip_status"]
            }[]
                           },
"my_trip_stats":
{ Args: { "p_weeks"?: number }; Returns: {
              "as_assistant": number,"as_driver": number,"avg_delay_minutes": number,"boarded": number,"cancelled": number,"completed": number,"field_trips": number,"late": number,"minutes_on_road": number,"missed": number,"on_time": number,"trips": number,"week_start": string
            }[]
                           },
"payment_quote":
{ Args: { "p_provider"?: string,"p_purpose": string,"p_target": string }; Returns: {
              "amount_xaf": number,"currency": string,"fee_xaf": number,"provider": string,"total_xaf": number
            }[]
                           },
"payments_to_check":
{ Args: { "p_limit"?: number }; Returns: {
              "created_at": string,"id": string,"status": string
            }[]
                           },
"payouts_to_send":
{ Args: { "p_limit"?: number }; Returns: {
              "action": string,"amount_xaf": number,"id": string,"phone": string,"provider": string
            }[]
                           },
"place_import_box":
{ Args: { "p_school_id": string }; Returns: {
              "east": number,"north": number,"south": number,"west": number
            }[]
                           },
"platform_add_infra_cost":
{ Args: { "p_amount_xaf": number,"p_label": string,"p_month": string,"p_note"?: string }; Returns: string
                           },
"platform_add_wallet_movement":
{ Args: { "p_amount_xaf": number,"p_kind": string,"p_note"?: string }; Returns: undefined
                           },
"platform_complete_follow_up":
{ Args: { "p_outreach_id": string }; Returns: undefined
                           },
"platform_confirm_payout_account":
{ Args: { "p_account": string }; Returns: undefined
                           },
"platform_create_school":
{ Args: { "p_city"?: string,"p_country"?: string,"p_domains"?: (string)[],"p_name": string,"p_short_name"?: string,"p_timezone"?: string }; Returns: string
                           },
"platform_delete_infra_cost":
{ Args: { "p_id": string }; Returns: undefined
                           },
"platform_follow_ups":
{ Args: Record<PropertyKey, never>; Returns: {
              "channel": string,"created_at": string,"follow_up_on": string,"id": string,"note": string,"school_id": string,"school_name": string
            }[]
                           },
"platform_infra_costs":
{ Args: { "p_from"?: string }; Returns: {
              "amount_xaf": number,"created_at": string,"id": string,"label": string,"month": string,"note": string
            }[]
                           },
"platform_invite_school_admin":
{ Args: { "p_email": string,"p_school_id": string }; Returns: string
                           },
"platform_lead":
{ Args: { "p_lead_id": string }; Returns: {
              "email": string,"id": string,"kind": string,"name": string,"organisation": string,"status": string
            }[]
                           },
"platform_lead_counts":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"platform_leads":
{ Args: { "p_kind"?: string,"p_limit"?: number,"p_offset"?: number,"p_status"?: string }; Returns: {
              "created_at": string,"email": string,"handled_at": string,"id": string,"kind": string,"locale": string,"message": string,"name": string,"note": string,"organisation": string,"school_id": string,"school_name": string,"status": string,"total": number
            }[]
                           },
"platform_log_outreach":
{ Args: { "p_channel": string,"p_follow_up_on"?: string,"p_note"?: string,"p_school_id": string,"p_signals"?: (string)[],"p_snooze_days"?: number }; Returns: string
                           },
"platform_lookup_account":
{ Args: { "p_email": string }; Returns: Json
                           },
"platform_overview":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"platform_payment_alerts":
{ Args: Record<PropertyKey, never>; Returns: {
              "amount_xaf": number,"at": string,"code": string,"id": string,"kind": string,"school_id": string,"school_name": string,"status": string
            }[]
                           },
"platform_payment_settings":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"platform_payments_overview":
{ Args: { "p_months"?: number }; Returns: Json
                           },
"platform_schedule_deletion":
{ Args: { "p_schedule": boolean,"p_user_id": string }; Returns: string
                           },
"platform_school":
{ Args: { "p_school_id": string }; Returns: Json
                           },
"platform_school_contacts":
{ Args: { "p_school_id": string }; Returns: Json
                           },
"platform_school_invites":
{ Args: { "p_school_id": string }; Returns: {
              "created_at": string,"email": string,"expires_at": string,"role": Database["public"]['Enums']["user_role"]
            }[]
                           },
"platform_school_outreach":
{ Args: { "p_school_id": string }; Returns: Json
                           },
"platform_school_payments":
{ Args: { "p_school": string }; Returns: Json
                           },
"platform_schools":
{ Args: Record<PropertyKey, never>; Returns: {
              "created_at": string,"id": string,"last_admin_action_at": string,"last_outreach_at": string,"level": number,"logo_path": string,"name": string,"reasons": Json,"score": number,"short_name": string,"snoozed": Json,"staff": number,"status": string,"students": number
            }[]
                           },
"platform_send_notice":
{ Args: { "p_body": string,"p_body_doc"?: Json,"p_follow_up_on"?: string,"p_link_path"?: string,"p_school_id": string,"p_signals"?: (string)[],"p_snooze_days"?: number }; Returns: string
                           },
"platform_set_payment_settings":
{ Args: { "p_settings": Json }; Returns: undefined
                           },
"platform_set_provider_rate":
{ Args: { "p_fixed_xaf"?: number,"p_operation": string,"p_percent": number,"p_provider": string }; Returns: undefined
                           },
"platform_set_school_payment_terms":
{ Args: { "p_charge_month_xaf"?: number,"p_charge_semester_xaf"?: number,"p_charges_from"?: string,"p_enabled": boolean,"p_school": string }; Returns: undefined
                           },
"platform_set_school_status":
{ Args: { "p_active": boolean,"p_school_id": string }; Returns: undefined
                           },
"platform_system_health":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"platform_update_lead":
{ Args: { "p_lead_id": string,"p_note"?: string,"p_school_id"?: string,"p_status": string }; Returns: undefined
                           },
"price_breakdown":
{ Args: { "p_fees_paid_by"?: string,"p_price"?: number }; Returns: {
              "busin_charge": number,"method": string,"school_receives": number,"student_pays": number,"transaction_cost": number
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
"record_wallet_balance":
{ Args: { "p_balance_xaf": number }; Returns: undefined
                           },
"refunds_to_send":
{ Args: { "p_limit"?: number }; Returns: {
              "action": string,"currency": string,"id": string,"payment_id": string,"total_xaf": number
            }[]
                           },
"register_device_token":
{ Args: { "p_locale"?: string,"p_platform": string,"p_token": string }; Returns: undefined
                           },
"request_account_deletion":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"request_refund":
{ Args: { "p_payment": string,"p_reason": string }; Returns: string
                           },
"request_school":
{ Args: { "p_school_id": string }; Returns: undefined
                           },
"request_staff_access":
{ Args: { "p_school_id": string }; Returns: undefined
                           },
"rotate_my_qr_secret":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"route_waypoints":
{ Args: { "p_extra_afters"?: (number)[],"p_extra_lats"?: (number)[],"p_extra_lngs"?: (number)[],"p_extra_names"?: (string)[],"p_stop_ids"?: (string)[] }; Returns: {
              "id": string,"kind": string,"lat": number,"lng": number,"name": string,"route_hash": string,"seq": number
            }[]
                           },
"school_balance":
{ Args: Record<PropertyKey, never>; Returns: {
              "available_xaf": number,"on_hold_xaf": number,"owed_xaf": number
            }[]
                           },
"school_leaderboard":
{ Args: { "p_limit"?: number,"p_semester_id": string }; Returns: {
              "avatar_url": string,"current_streak": number,"display_name": string,"is_me": boolean,"rank": number,"rides": number
            }[]
                           },
"school_route":
{ Args: Record<PropertyKey, never>; Returns: {
              "campus_lat": number,"campus_lng": number,"campus_name": string,"computed_at": string,"current": boolean,"distance_m": number,"duration_s": number,"geometry": Json,"legs": Json,"name": string,"route_id": string,"stops": Json
            }[]
                           },
"search_places":
{ Args: { "p_limit"?: number,"p_query": string }; Returns: {
              "kind": string,"label": string,"lat": number,"lng": number
            }[]
                           },
"service_store_route":
{ Args: { "p_distance_m": number,"p_duration_s": number,"p_geojson": string,"p_hash": string,"p_legs": Json,"p_school": string }; Returns: boolean
                           },
"set_my_area":
{ Args: { "p_label": string,"p_lat": number,"p_lng": number,"p_source": string }; Returns: undefined
                           },
"set_notification_preferences":
{ Args: { "p_boarding_messages_on": boolean,"p_bus_near_minutes": number,"p_bus_near_on": boolean,"p_evening_on": boolean,"p_evening_time": string,"p_morning_on": boolean,"p_morning_time": string,"p_riding_days": number }; Returns: undefined
                           },
"set_payment_preference":
{ Args: { "p_preference": string }; Returns: undefined
                           },
"set_streak_opt_in":
{ Args: { "p_on": boolean }; Returns: undefined
                           },
"settle_payment":
{ Args: { "p_amount"?: string,"p_currency"?: string,"p_failure_code"?: string,"p_failure_message"?: string,"p_id": string,"p_provider_txn"?: string,"p_status": string }; Returns: Json
                           },
"settle_payout":
{ Args: { "p_amount"?: string,"p_currency"?: string,"p_failure_code"?: string,"p_id": string,"p_provider_txn"?: string,"p_status": string }; Returns: Json
                           },
"settle_refund":
{ Args: { "p_amount"?: string,"p_currency"?: string,"p_failure_code"?: string,"p_id": string,"p_provider_txn"?: string,"p_status": string }; Returns: Json
                           },
"staff_day_keys":
{ Args: Record<PropertyKey, never>; Returns: {
              "avatar_url": string,"day": string,"day_key": string,"full_name": string,"matricule": string,"stop_id": string,"student_id": string
            }[]
                           },
"start_field_trip":
{ Args: { "p_bus_id": string,"p_direction": Database["public"]['Enums']["trip_direction"],"p_other_id"?: string,"p_role": string }; Returns: string
                           },
"start_payment":
{ Args: { "p_phone": string,"p_provider": string,"p_purpose": string,"p_target": string }; Returns: {
              "amount_xaf": number,"currency": string,"fee_xaf": number,"id": string,"provider": string,"total_xaf": number
            }[]
                           },
"start_trip":
{ Args: { "p_trip_id": string }; Returns: undefined
                           },
"submit_installment_proof":
{ Args: { "p_installment": string,"p_path": string }; Returns: undefined
                           },
"submit_interest":
{ Args: { "p_email": string,"p_kind": string,"p_locale"?: string,"p_message"?: string,"p_name"?: string,"p_organisation"?: string,"p_trap"?: string }; Returns: string
                           },
"trip_manifest":
{ Args: { "p_trip_id": string }; Returns: {
              "avatar_url": string,"full_name": string,"matricule": string,"scan_id": string,"scanned_at": string,"stop_id": string,"student_id": string
            }[]
                           },
"trip_position_holder":
{ Args: { "p_trip_id": string }; Returns: {
              "holder_id": string,"holder_name": string,"is_me": boolean,"seconds_ago": number
            }[]
                           },
"unregister_device_token":
{ Args: { "p_token": string }; Returns: undefined
                           },
"wallet_snapshot_due":
{ Args: Record<PropertyKey, never>; Returns: boolean
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
