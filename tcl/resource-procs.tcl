ad_library {

    Support for the JavaScript/Typescrip Highcharts library-

    This script defines the following public procs:

    ::highcharts::resource_info
    ::highcharts::download

    @author Gustaf Neumann
    @creation-date 23 Oct 2022
}

namespace eval ::highcharts {

    set package_id [apm_package_id_from_key "highcharts"]

    #
    # The Highcharts configuration can be tailored via the OpenACS
    # configuration file:
    #
    #    ns_section ns/server/${server}/acs/highcharts
    #        ns_param HighchartsVersion 11.0.1
    #
    #  For new versions, checkout https://cdnjs.com/
    #
    set ::highcharts::version [parameter::get \
                                   -package_id $package_id \
                                   -parameter HighchartsVersion \
                                   -default 11.2.0]

    ad_proc ::highcharts::resource_info {
        {-version ""}
    } {

        Get information about available version(s) of Highcharts,
        from the local filesystem, or from CDN.

    } {
        #
        # If no version is specified, use the namespaced variable.
        #
        if {$version eq ""} {
            set version $::highcharts::version
        }

        #
        # Setup variables for access via CDN vs. local resources.
        #
        set resourceDir [acs_package_root_dir highcharts/www/resources]
        set resourceUrl /resources/highcharts/$version
        set cdnHost     cdnjs.cloudflare.com
        set cdn         //$cdnHost/

        if {[file exists $resourceDir/$version]} {
            #
            # Local version is installed
            #
            set prefix $resourceUrl/code
            set cdnHost ""
            set cspMap ""
        } else {
            #
            # Use CDN
            #
            # cloudflare has the following resources:
            #
            #    https://cdnjs.cloudflare.com/ajax/libs/highcharts/10.2.1/highcharts.js
            #    https://cdnjs.cloudflare.com/ajax/libs/highcharts/10.2.1/highcharts.min.js
            #
            #    https://cdnjs.cloudflare.com/ajax/libs/highcharts/10.2.1/modules/exporting.js
            #    https://cdnjs.cloudflare.com/ajax/libs/highcharts/10.2.1/modules/exporting.min.js
            #
            set prefix ${cdn}ajax/libs/highcharts/$version
            set cspMap [subst {
                urn:ad:js:highcharts {
                    script-src $cdnHost
                }}]
            #
            #
            # Other potential sources:
            #
            # https://www.highcharts.com/blog/download/
            # https://www.jsdelivr.com/package/npm/highcharts
        }

        #
        # Return the dict with at least the required fields
        #
        lappend result \
            resourceName "Highcharts" \
            resourceDir $resourceDir \
            cdn $cdn \
            cdnHost $cdnHost \
            prefix $prefix \
            cssFiles {} \
            jsFiles  {} \
            extraFiles {} \
            downloadURLs [subst {
                https://code.highcharts.com/zips/Highcharts-$version.zip
            }] \
            cspMap $cspMap \
            urnMap {} \
            versionCheckURL "https://cdnjs.com/libraries?q=highcharts"

        return $result
    }

    ad_proc -private ::highcharts::download {
        {-version ""}
    } {
        Download Highcharts in the specified version and put it
        into a directory structure similar to the CDN to support the
        installation of multiple versions.
    } {
        #
        # If no version is specified, use the namespaced variable.
        #
        if {$version eq ""} {
            set version ${::highcharts::version}
        }

        set resource_info [resource_info -version $version]
        ::util::resources::download \
            -resource_info $resource_info \
            -version_dir $version

        set resourceDir [dict get $resource_info resourceDir]
        ns_log notice " ::highcharts::download resourceDir $resourceDir"

        #
        # Do we have unzip installed?
        #
        set unzip [::util::which unzip]
        if {$unzip eq ""} {
            error "can't install Highcharts locally; no unzip program found on PATH"
        }

        #
        # Do we have a writable output directory under resourceDir?
        #
        if {![file isdirectory $resourceDir]} {
            file mkdir $resourceDir
        }
        if {![file writable $resourceDir]} {
            error "directory $resourceDir is not writable"
        }

        #
        # So far, everything is fine, unpack the downloaded zip file
        #
        foreach url [dict get $resource_info downloadURLs] {
            set fn [file tail $url]
            util::unzip \
                -overwrite \
                -source $resourceDir/$version/$fn \
                -destination $resourceDir/$version
        }
    }

    ad_proc -private ::highcharts::register_urns {} {
        Register URNs either with local or with CDN URLs.
    } {
        set resource_info [::highcharts::resource_info]
        set prefix [dict get $resource_info prefix]

        if {[dict exists $resource_info cdnHost] && [dict get $resource_info cdnHost] ne ""} {
            #
            # Settings for the CDN, in case it differs
            #
            dict set URNs urn:ad:js:highcharts $prefix/highcharts.min.js
            dict set URNs urn:ad:js:highcharts-more $prefix/highcharts-more.min.js
            dict set URNs urn:ad:js:highcharts/modules/exporting $prefix/modules/exporting.min.js
            dict set URNs urn:ad:js:highcharts/modules/accessibility $prefix/modules/accessibility.min.js

        } else {
            #
            # Settings for local installs
            #
            dict set URNs urn:ad:js:highcharts $prefix/highcharts.js
            dict set URNs urn:ad:js:highcharts-more $prefix/highcharts-more.js
            dict set URNs urn:ad:js:highcharts/modules/exporting $prefix/modules/exporting.js
            dict set URNs urn:ad:js:highcharts/modules/accessibility $prefix/modules/accessibility.js
        }

        foreach {URN resource} $URNs {
            template::register_urn \
                -urn $URN \
                -resource $resource \
                -csp_list [expr {[dict exists $resource_info cspMap $URN]
                                 ? [dict get $resource_info cspMap $URN]
                                 : ""}]
        }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
