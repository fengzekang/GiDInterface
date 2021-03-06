namespace eval DEM::xml {
    variable dir
}

proc DEM::xml::Init { } {
    variable dir
    Model::InitVariables dir $DEM::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getMaterials Materials.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
}

proc DEM::xml::getUniqueName {name} {
    return DEM$name
}

proc DEM::xml::MultiAppEvent {args} {

}

proc DEM::xml::CustomTree { args } {
    spdAux::SetValueOnTreeItem values OpenMP ParallelType
    spdAux::SetValueOnTreeItem state hidden DEMTimeParameters StartTime
}


proc DEM::xml::InsertConstitutiveLawForParameters {input arguments} {
    return {<value n='ConstitutiveLaw' pn='Constitutive law' v='' actualize_tree='1' values='[GetConstitutiveLaws]' dict='[GetAllConstitutiveLaws]'  help='Select a constitutive law'>
        <dependencies node="../value[@n = 'Material']" actualize='1'/>
        </value>
        <value n='Material' pn='Material' editable='0' help='Choose a material from the database' values='[get_materials_list_simple]' v='DEM-DefaultMaterial' state='normal' />
    }
}


DEM::xml::Init
