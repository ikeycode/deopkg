/*
 * This file is part of gtkD.
 *
 * gtkD is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or (at your option) any later version, with
 * some exceptions, please read the COPYING file.
 *
 * gtkD is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with gtkD; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
 */

// generated automatically - do not change
// find conversion definition on APILookup.txt
// implement new conversion functionalities the gir-to-d pakage


module gio.StaticResource;

private import gio.Resource;
private import gio.c.functions;
public  import gio.c.types;
private import gobject.ObjectG;


/**
 * #GStaticResource is an opaque data structure and can only be accessed
 * using the following functions.
 */
public class StaticResource
{
	/** the main Gtk struct */
	protected GStaticResource* gStaticResource;
	protected bool ownedRef;

	/** Get the main Gtk struct */
	public GStaticResource* getStaticResourceStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gStaticResource;
	}

	/** the main Gtk struct as a void* */
	protected void* getStruct()
	{
		return cast(void*)gStaticResource;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GStaticResource* gStaticResource, bool ownedRef = false)
	{
		this.gStaticResource = gStaticResource;
		this.ownedRef = ownedRef;
	}


	/**
	 * Finalized a GResource initialized by g_static_resource_init().
	 *
	 * This is normally used by code generated by
	 * [glib-compile-resources][glib-compile-resources]
	 * and is not typically used by other code.
	 *
	 * Since: 2.32
	 */
	public void fini()
	{
		g_static_resource_fini(gStaticResource);
	}

	/**
	 * Gets the GResource that was registered by a call to g_static_resource_init().
	 *
	 * This is normally used by code generated by
	 * [glib-compile-resources][glib-compile-resources]
	 * and is not typically used by other code.
	 *
	 * Returns: a #GResource
	 *
	 * Since: 2.32
	 */
	public Resource getResource()
	{
		auto __p = g_static_resource_get_resource(gStaticResource);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Resource)(cast(GResource*) __p);
	}

	/**
	 * Initializes a GResource from static data using a
	 * GStaticResource.
	 *
	 * This is normally used by code generated by
	 * [glib-compile-resources][glib-compile-resources]
	 * and is not typically used by other code.
	 *
	 * Since: 2.32
	 */
	public void init()
	{
		g_static_resource_init(gStaticResource);
	}
}
