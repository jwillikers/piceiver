#!/usr/bin/env nu

# Get the object.id of a PipeWire node.
def get_node_object_id [
    node_name: string # The info.props."node.name"
    media_class: string # The media.class type of the node, i.e. "Audio/Sink"
] [ string -> string ] {
    (
        $in
        | from json
        | where type == "PipeWire:Interface:Node"
        | where info.props."node.name" == $node_name
        | where info.props."media.class" == $media_class
        | get id
        | first
    )
}

# Set the volume and the default source and sink in WirePlumber.
def main [] {
    let pw_dump = (^pw-dump)
    ^wpctl set-default ($pw_dump | get_node_object_id alsa_input.platform-1000110000.pcie-pci-0000_02_00.0.iec958-stereo Audio/Source)
    ^wpctl set-default ($pw_dump | get_node_object_id Combined_Stereo_Sink Audio/Sink)
    ^wpctl set-volume ($pw_dump | get_node_object_id snapserver Audio/Sink) 60%
    ^wpctl set-volume ($pw_dump | get_node_object_id alsa_output.platform-1000110000.pcie-pci-0000_02_00.0.iec958-stereo Audio/Sink) 40%
    ^wpctl set-volume ($pw_dump | get_node_object_id alsa_output.platform-soc_sound.stereo-fallback Audio/Sink) 85%
    ^wpctl set-volume ($pw_dump | get_node_object_id alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo Audio/Sink) 80%
}
