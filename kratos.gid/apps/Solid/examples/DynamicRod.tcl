
proc ::Solid::examples::DynamicRod {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawDynamicRodGeometry$::Model::SpatialDimension
    #AssignDynamicRodMeshSizes$::Model::SpatialDimension
    #TreeAssignationDynamicRod$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawDynamicRodGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples DynamicRod3D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawDynamicRodGeometry2D {args} {
    Kratos::ResetModel
    #GiD_Process Mescape Files InsertGeom DynamicRod3D.gid
}

# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationDynamicRod3D {args} {
    TreeAssignationDynamicRod2D
    AddCuts
}
proc Solid::examples::TreeAssignationDynamicRod2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Solid Parts
    set solidParts [spdAux::getRoute "FLParts"]
    set solidNode [customlib::AddConditionGroupOnXPath $solidParts Solid]
    # set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002 YIELD_STRESS 0 POWER_LAW_K 1 POWER_LAW_N 1]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002]
    foreach {prop val} $props {
        set propnode [$solidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

    set solidConditions [spdAux::getRoute "FLBC"]

    # Solid Inlet
    set solidInlet "$solidConditions/condition\[@n='AutomaticInlet$nd'\]"
    set inlets [list inlet1 0 1 "6*y*(1-y)*sin(pi*t*0.5)" inlet2 1 End "6*y*(1-y)"]
    ErasePreviousIntervals
    foreach {interval_name ini end function} $inlets {
        spdAux::CreateInterval $interval_name $ini $end
        GiD_Groups create "Inlet//$interval_name"
        GiD_Groups edit state "Inlet//$interval_name" hidden
        spdAux::AddIntervalGroup Inlet "Inlet//$interval_name"
        set inletNode [customlib::AddConditionGroupOnXPath $solidInlet "Inlet//$interval_name"]
        $inletNode setAttribute ov $condtype
        set props [list ByFunction Yes function_modulus $function direction automatic_inwards_normal Interval $interval_name]
        foreach {prop val} $props {
             set propnode [$inletNode selectNodes "./value\[@n = '$prop'\]"]
             if {$propnode ne "" } {
                  $propnode setAttribute v $val
             } else {
                W "Warning - Couldn't find property Inlet $prop"
            }
        }
    }

    # Solid Outlet
    set solidOutlet "$solidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $solidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    foreach {prop val} $props {
         set propnode [$outletNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }

    # Solid Conditions
    [customlib::AddConditionGroupOnXPath "$solidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Walls] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$solidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Cylinder] setAttribute ov $condtype

    # Time parameters
    set time_parameters [list EndTime 45 DeltaTime 0.1]
    set time_params_path [spdAux::getRoute "FLTimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Output
    set time_parameters [list OutputControlType step OutputDeltaStep 1]
    set time_params_path [spdAux::getRoute "Results"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    spdAux::RequestRefresh
}
