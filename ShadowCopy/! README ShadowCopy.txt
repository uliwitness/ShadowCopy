SHADOWCOPY 0.2
--------------

WHAT IS IT?

Shadow Copy is a small tool that tricks Spotlight into indexing your CDs so you can search over them even while they're not inserted. It achieves this by creating folders with aliases to all files of a CD on your hard disk.


HOW DO I USE IT?

Add ShadowCopy to your Login Items (System Preferences, "Users" pane). When next you log in, ShadowCopy will be launched in the background (you'll see this because a small CD icon will show for three seconds in the upper right of your menu bar). It will sit there using no CPU until a new drive is mounted. When that happens, it will create a "shadow copy" (i.e. only folders and file aliases) of this CD in a folder named DiskIndex in your user folder.


ANY DOWNSIDES?

Since ShadowCopy uses the name of a volume to tell it from other volumes, you're out of luck if you have lots of CDs named "Untitled CD".

ShadowCopy will only index CDs and DVDs on its own accord. Any other volumes you want indexed must be dragged onto its icon to explicitly make it index them.


REVISIONS:
0.1	First Public Release
0.2	Added more comments, made this check whether indexed volume is a CD or DVD and only auto-index in that case.


WHO DID THIS? WHERE CAN I GET NEW VERSIONS?

ShadowCopy was created by M. Uli Kusterer, (c) 2005. Source code is available. You may freely redistribute modified copies as long as any changes you make to the sources are contributed and licensed back to Uli Kusterer, they are marked as having been changed and you don't remove any of the copyright notices from the source files and application.

To obtain a current version of ShadowCopy, see Uli's web site at http://www.zathras.de.

Uli can be reached via E-Mail at: witness (at) zathras (dot) de or witness (dot) of (dot) teachtext (at) gmx (dot) net.