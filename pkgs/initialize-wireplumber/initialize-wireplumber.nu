#!/usr/bin/env nu

# Get the object.id of a PipeWire node, or nothing if the node doesn't exist.
def get_node_object_id [
    node_name: string # The info.props."node.name"
    media_class: string # The media.class type of the node, i.e. "Audio/Sink"
]: string -> any {
    (
        $in
        | from json
        | where type == "PipeWire:Interface:Node"
        | where {|node| $node.info.props."node.name"? == $node_name }
        | where {|node| $node.info.props."media.class"? == $media_class }
        | get id
        | get 0?
    )
}

# Run a wpctl command on a node.
# A missing node is skipped with a warning, so that one missing device doesn't prevent setting up the others.
def wpctl_node [
    pw_dump: string # The output of pw-dump
    node_name: string # The info.props."node.name"
    media_class: string # The media.class type of the node, i.e. "Audio/Sink"
    command: string # The wpctl command, i.e. "set-default"
    ...arguments: string # Extra arguments for the wpctl command, i.e. the volume
]: nothing -> bool {
    let id = ($pw_dump | get_node_object_id $node_name $media_class)
    if $id == null {
        print --stderr $"Skipping wpctl ($command) for the missing ($media_class) node ($node_name)"
        return false
    }
    ^wpctl $command $id ...$arguments
    true
}

# Set the volume and the default source and sink in WirePlumber.
def main [] {
    let pw_dump = (^pw-dump)
    let results = [
        (wpctl_node $pw_dump alsa_input.platform-1000110000.pcie-pci-0001_02_00.0.iec958-stereo Audio/Source set-default)
        (wpctl_node $pw_dump Combined_Stereo_Sink Audio/Sink set-default)
        (wpctl_node $pw_dump alsa_output.platform-1000110000.pcie-pci-0001_02_00.0.iec958-stereo Audio/Sink set-volume 40%)
        (wpctl_node $pw_dump alsa_output.platform-soc_107c000000_sound.stereo-fallback Audio/Sink set-volume 85%)
        (wpctl_node $pw_dump alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo Audio/Sink set-volume 50%)
    ]
    let skipped = ($results | where {|result| not $result } | length)
    if $skipped > 0 {
        print --stderr $"Skipped ($skipped) missing nodes"
    }
}
