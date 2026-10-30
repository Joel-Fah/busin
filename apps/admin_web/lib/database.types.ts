
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
                    "capacity": number,"created_at": string,"id": string,"in_service": boolean,"plate": string,"school_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "capacity": number,"created_at"?: string,"id"?: string,"in_service"?: boolean,"plate": string,"school_id": string
                  }
                  Update: {
                    "capacity"?: number,"created_at"?: string,"id"?: string,"in_service"?: boolean,"plate"?: string,"school_id"?: string
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
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"department": string | null,"email": string,"full_name": string,"id": string,"matricule": string | null,"phone": string | null,"program": string | null,"role": Database["public"]['Enums']["user_role"],"school_id": string,"status": Database["public"]['Enums']["account_status"],"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"department"?: string | null,"email": string,"full_name"?: string,"id": string,"matricule"?: string | null,"phone"?: string | null,"program"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id": string,"status"?: Database["public"]['Enums']["account_status"],"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"department"?: string | null,"email"?: string,"full_name"?: string,"id"?: string,"matricule"?: string | null,"phone"?: string | null,"program"?: string | null,"role"?: Database["public"]['Enums']["user_role"],"school_id"?: string,"status"?: Database["public"]['Enums']["account_status"],"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "profiles_school_id_fkey"
      columns: ["school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["id"]
    }
                  ]
                },"scans": {
                  Row: {
                    "accuracy_m": number | null,"id": string,"location": unknown,"scanned_at": string,"scanned_by": string,"school_id": string,"stop_id": string | null,"student_id": string,"subscription_id": string,"trip_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "accuracy_m"?: number | null,"id"?: string,"location"?: unknown,"scanned_at"?: string,"scanned_by": string,"school_id": string,"stop_id"?: string | null,"student_id": string,"subscription_id": string,"trip_id": string
                  }
                  Update: {
                    "accuracy_m"?: number | null,"id"?: string,"location"?: unknown,"scanned_at"?: string,"scanned_by"?: string,"school_id"?: string,"stop_id"?: string | null,"student_id"?: string,"subscription_id"?: string,"trip_id"?: string
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
                    "created_at": string,"id": string,"name": string,"short_name": string | null,"status": string,"timezone": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"id"?: string,"name": string,"short_name"?: string | null,"status"?: string,"timezone"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"name"?: string,"short_name"?: string | null,"status"?: string,"timezone"?: string
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
                },"trips": {
                  Row: {
                    "bus_id": string,"created_at": string,"direction": Database["public"]['Enums']["trip_direction"],"driver_id": string | null,"ended_at": string | null,"id": string,"scheduled_start": string,"school_id": string,"started_at": string | null,"status": Database["public"]['Enums']["trip_status"]
                  }
                  ComputedFields: never
                  Insert: {
                    "bus_id": string,"created_at"?: string,"direction": Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"scheduled_start": string,"school_id": string,"started_at"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
                  }
                  Update: {
                    "bus_id"?: string,"created_at"?: string,"direction"?: Database["public"]['Enums']["trip_direction"],"driver_id"?: string | null,"ended_at"?: string | null,"id"?: string,"scheduled_start"?: string,"school_id"?: string,"started_at"?: string | null,"status"?: Database["public"]['Enums']["trip_status"]
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
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "admin_review_subscription":
{ Args: { "p_decision": string,"p_note"?: string,"p_subscription_id": string }; Returns: undefined
                           },
"admin_set_user_role":
{ Args: { "p_role": Database["public"]['Enums']["user_role"],"p_user_id": string }; Returns: undefined
                           },
"admin_set_user_status":
{ Args: { "p_status": Database["public"]['Enums']["account_status"],"p_user_id": string }; Returns: undefined
                           },
"custom_access_token_hook":
{ Args: { "event": Json }; Returns: Json
                           },
"get_my_qr_secret":
{ Args: Record<PropertyKey, never>; Returns: string
                           },
"record_qr_scan":
{ Args: { "p_accuracy"?: number,"p_code": string,"p_lat"?: number,"p_lng"?: number,"p_stop_id"?: string,"p_trip_id": string }; Returns: Json
                           },
"rotate_my_qr_secret":
{ Args: Record<PropertyKey, never>; Returns: string
                           }
          }
          Enums: {
            "account_status": "pending"|"verified"|"suspended","semester_name": "fall"|"spring"|"summer","subscription_status": "pending"|"approved"|"rejected"|"expired","trip_direction": "inbound"|"outbound","trip_status": "scheduled"|"active"|"completed"|"cancelled","user_role": "student"|"staff"|"admin"
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
            "account_status": ["pending", "verified", "suspended"],"semester_name": ["fall", "spring", "summer"],"subscription_status": ["pending", "approved", "rejected", "expired"],"trip_direction": ["inbound", "outbound"],"trip_status": ["scheduled", "active", "completed", "cancelled"],"user_role": ["student", "staff", "admin"]
          }
        }
} as const
