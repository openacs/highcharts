ad_page_contract {
    @author Gustaf Neumann

    @creation-date Aug 6, 2018
} {
}

set resource_info [::highcharts::resource_info]
set version [dict get $resource_info configuredVersion]
set download_url download?version=$version

set title "[dict get $resource_info resourceName] Package - Sitewide Admin"
set context [list $title]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
