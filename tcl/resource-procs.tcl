ad_library {

    Support for the JavaScript/Typescrip Highcharts library-

    This script defines the following public procs:

    ::highcharts::resource_info
    ::highcharts::download

    @author Gustaf Neumann
    @creation-date 23 Oct 2022
}

namespace eval ::highcharts {
    variable parameter_info

    #
    # The version configuration can be tailored via the OpenACS
    # configuration file:
    #
    #    ns_section ns/server/${server}/acs/highcharts
    #        ns_param HighchartsVersion 11.4.7
    #
    set parameter_info {
        package_key highcharts
        parameter_name HighchartsVersion
        default_value 11.4.7
    }

    ad_proc ::highcharts::resource_info {
        {-version ""}
    } {

        Get information about available version(s) of Highcharts,
        from the local filesystem, or from CDN.

    } {
        variable parameter_info
        #
        # If no version is specified, use the configured value.
        #
        if {$version eq ""} {
             dict with parameter_info {
                 set version [::parameter::get_global_value \
                                  -package_key $package_key \
                                  -parameter $parameter_name \
                                  -default $default_value]
             }
        }

        #
        # Setup variables for access via CDN vs. local resources.
        #
        set resourceDir [acs_package_root_dir highcharts/www/resources]
        set cdnHost     cdnjs.cloudflare.com
        set cdn         //$cdnHost/

        if {[file exists $resourceDir/$version]} {
            #
            # Local version is installed
            #
            set prefix /resources/highcharts/$version/code
            set cdnHost ""
            set cspMap ""
            dict set URNs urn:ad:js:highcharts highcharts.js
            dict set URNs urn:ad:js:highcharts-more highcharts-more.js
            dict set URNs urn:ad:js:highcharts/modules/exporting modules/exporting.js
            dict set URNs urn:ad:js:highcharts/modules/accessibility modules/accessibility.js

        } else {
            #
            # Use CDN
            #
            set prefix ${cdn}ajax/libs/highcharts/$version
            #
            # Use minified versions from CDN
            #
            dict set URNs urn:ad:js:highcharts highcharts.min.js
            dict set URNs urn:ad:js:highcharts-more highcharts-more.min.js
            dict set URNs urn:ad:js:highcharts/modules/exporting modules/exporting.min.js
            dict set URNs urn:ad:js:highcharts/modules/accessibility modules/accessibility.min.js
            
            dict set cspMap urn:ad:js:highcharts script-src $cdnHost
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
            urnMap $URNs \
            versionCheckAPI {cdn cdnjs library highcharts count 5} \
            vulnerabilityCheck {service snyk library highcharts} \
            parameterInfo $parameter_info \
            configuredVersion $version

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
        # Get resource_info for the specified version
        #
        set resource_info [resource_info -version $version]
        set resourceDir [dict get $resource_info resourceDir]
        set versionSegment [::util::resources::version_segment -resource_info $resource_info]

        ::util::resources::download -resource_info $resource_info

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
                -source $resourceDir/$versionSegment/$fn \
                -destination $resourceDir/$versionSegment
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
