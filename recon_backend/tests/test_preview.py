def preview(client, headers, lat=42.4534891, lon=-76.4735249):
    return client.get(f"/v1/parties/preview?lat={lat}&lon={lon}", headers=headers)


def element(id_, name, tags=None):
    return {
        "type": "node",
        "id": id_,
        "lat": 42.45,
        "lon": -76.47,
        "tags": {"name": name, "amenity": "restaurant", **(tags or {})},
    }


def test_preview_returns_a_nearby_place(client, host, stub_overpass):
    stub_overpass({"elements": [element(1, "Corner Diner"), element(2, "Thai Villa")]})

    response = preview(client, host)
    assert response.status_code == 200
    payload = response.get_json()

    assert payload["place"]["name"] == "Corner Diner"
    assert payload["count"] == 2
    assert payload["provider"] == "overpass"


def test_preview_prefers_a_place_that_has_a_photo(client, host, stub_overpass):
    stub_overpass(
        {
            "elements": [
                element(1, "No Photo Cafe"),
                element(2, "Pictured Bistro", {"image": "https://example.com/b.jpg"}),
            ]
        }
    )

    payload = preview(client, host).get_json()
    assert payload["place"]["name"] == "Pictured Bistro"
    assert payload["place"]["image_url"] == "https://example.com/b.jpg"


def test_preview_falls_back_to_the_seed_catalogue(client, host):
    """The autouse guard makes overpass unavailable."""
    payload = preview(client, host).get_json()

    assert payload["provider"] == "seed"
    assert payload["place"]["name"]


def test_preview_validates_coordinates(client, host):
    assert client.get("/v1/parties/preview", headers=host).status_code == 400
    assert preview(client, host, lat=999).status_code == 400


def test_preview_needs_auth(client):
    assert client.get("/v1/parties/preview?lat=42.4&lon=-76.4").status_code == 401
