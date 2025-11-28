// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $ChantsTableTable extends ChantsTable
    with TableInfo<$ChantsTableTable, ChantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChantsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titreMeta = const VerificationMeta('titre');
  @override
  late final GeneratedColumn<String> titre = GeneratedColumn<String>(
      'titre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categorieMeta =
      const VerificationMeta('categorie');
  @override
  late final GeneratedColumn<String> categorie = GeneratedColumn<String>(
      'categorie', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _auteurMeta = const VerificationMeta('auteur');
  @override
  late final GeneratedColumn<String> auteur = GeneratedColumn<String>(
      'auteur', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlAudioMeta =
      const VerificationMeta('urlAudio');
  @override
  late final GeneratedColumn<String> urlAudio = GeneratedColumn<String>(
      'url_audio', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dureeMeta = const VerificationMeta('duree');
  @override
  late final GeneratedColumn<int> duree = GeneratedColumn<int>(
      'duree', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
      'lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partitionUrlMeta =
      const VerificationMeta('partitionUrl');
  @override
  late final GeneratedColumn<String> partitionUrl = GeneratedColumn<String>(
      'partition_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCachedMeta =
      const VerificationMeta('isCached');
  @override
  late final GeneratedColumn<bool> isCached = GeneratedColumn<bool>(
      'is_cached', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cached" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        titre,
        categorie,
        auteur,
        urlAudio,
        duree,
        createdAt,
        type,
        lyrics,
        partitionUrl,
        isCached,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chants_table';
  @override
  VerificationContext validateIntegrity(Insertable<ChantsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('titre')) {
      context.handle(
          _titreMeta, titre.isAcceptableOrUnknown(data['titre']!, _titreMeta));
    } else if (isInserting) {
      context.missing(_titreMeta);
    }
    if (data.containsKey('categorie')) {
      context.handle(_categorieMeta,
          categorie.isAcceptableOrUnknown(data['categorie']!, _categorieMeta));
    } else if (isInserting) {
      context.missing(_categorieMeta);
    }
    if (data.containsKey('auteur')) {
      context.handle(_auteurMeta,
          auteur.isAcceptableOrUnknown(data['auteur']!, _auteurMeta));
    } else if (isInserting) {
      context.missing(_auteurMeta);
    }
    if (data.containsKey('url_audio')) {
      context.handle(_urlAudioMeta,
          urlAudio.isAcceptableOrUnknown(data['url_audio']!, _urlAudioMeta));
    } else if (isInserting) {
      context.missing(_urlAudioMeta);
    }
    if (data.containsKey('duree')) {
      context.handle(
          _dureeMeta, duree.isAcceptableOrUnknown(data['duree']!, _dureeMeta));
    } else if (isInserting) {
      context.missing(_dureeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('lyrics')) {
      context.handle(_lyricsMeta,
          lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta));
    }
    if (data.containsKey('partition_url')) {
      context.handle(
          _partitionUrlMeta,
          partitionUrl.isAcceptableOrUnknown(
              data['partition_url']!, _partitionUrlMeta));
    }
    if (data.containsKey('is_cached')) {
      context.handle(_isCachedMeta,
          isCached.isAcceptableOrUnknown(data['is_cached']!, _isCachedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChantsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChantsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      titre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titre'])!,
      categorie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categorie'])!,
      auteur: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}auteur'])!,
      urlAudio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url_audio'])!,
      duree: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duree'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      lyrics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics']),
      partitionUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}partition_url']),
      isCached: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cached'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $ChantsTableTable createAlias(String alias) {
    return $ChantsTableTable(attachedDatabase, alias);
  }
}

class ChantsTableData extends DataClass implements Insertable<ChantsTableData> {
  final String id;
  final String titre;
  final String categorie;
  final String auteur;
  final String urlAudio;
  final int duree;
  final DateTime createdAt;
  final String type;
  final String? lyrics;
  final String? partitionUrl;
  final bool isCached;
  final DateTime? lastSyncedAt;
  const ChantsTableData(
      {required this.id,
      required this.titre,
      required this.categorie,
      required this.auteur,
      required this.urlAudio,
      required this.duree,
      required this.createdAt,
      required this.type,
      this.lyrics,
      this.partitionUrl,
      required this.isCached,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['titre'] = Variable<String>(titre);
    map['categorie'] = Variable<String>(categorie);
    map['auteur'] = Variable<String>(auteur);
    map['url_audio'] = Variable<String>(urlAudio);
    map['duree'] = Variable<int>(duree);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    if (!nullToAbsent || partitionUrl != null) {
      map['partition_url'] = Variable<String>(partitionUrl);
    }
    map['is_cached'] = Variable<bool>(isCached);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  ChantsTableCompanion toCompanion(bool nullToAbsent) {
    return ChantsTableCompanion(
      id: Value(id),
      titre: Value(titre),
      categorie: Value(categorie),
      auteur: Value(auteur),
      urlAudio: Value(urlAudio),
      duree: Value(duree),
      createdAt: Value(createdAt),
      type: Value(type),
      lyrics:
          lyrics == null && nullToAbsent ? const Value.absent() : Value(lyrics),
      partitionUrl: partitionUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(partitionUrl),
      isCached: Value(isCached),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory ChantsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChantsTableData(
      id: serializer.fromJson<String>(json['id']),
      titre: serializer.fromJson<String>(json['titre']),
      categorie: serializer.fromJson<String>(json['categorie']),
      auteur: serializer.fromJson<String>(json['auteur']),
      urlAudio: serializer.fromJson<String>(json['urlAudio']),
      duree: serializer.fromJson<int>(json['duree']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<String>(json['type']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      partitionUrl: serializer.fromJson<String?>(json['partitionUrl']),
      isCached: serializer.fromJson<bool>(json['isCached']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'titre': serializer.toJson<String>(titre),
      'categorie': serializer.toJson<String>(categorie),
      'auteur': serializer.toJson<String>(auteur),
      'urlAudio': serializer.toJson<String>(urlAudio),
      'duree': serializer.toJson<int>(duree),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<String>(type),
      'lyrics': serializer.toJson<String?>(lyrics),
      'partitionUrl': serializer.toJson<String?>(partitionUrl),
      'isCached': serializer.toJson<bool>(isCached),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  ChantsTableData copyWith(
          {String? id,
          String? titre,
          String? categorie,
          String? auteur,
          String? urlAudio,
          int? duree,
          DateTime? createdAt,
          String? type,
          Value<String?> lyrics = const Value.absent(),
          Value<String?> partitionUrl = const Value.absent(),
          bool? isCached,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      ChantsTableData(
        id: id ?? this.id,
        titre: titre ?? this.titre,
        categorie: categorie ?? this.categorie,
        auteur: auteur ?? this.auteur,
        urlAudio: urlAudio ?? this.urlAudio,
        duree: duree ?? this.duree,
        createdAt: createdAt ?? this.createdAt,
        type: type ?? this.type,
        lyrics: lyrics.present ? lyrics.value : this.lyrics,
        partitionUrl:
            partitionUrl.present ? partitionUrl.value : this.partitionUrl,
        isCached: isCached ?? this.isCached,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  ChantsTableData copyWithCompanion(ChantsTableCompanion data) {
    return ChantsTableData(
      id: data.id.present ? data.id.value : this.id,
      titre: data.titre.present ? data.titre.value : this.titre,
      categorie: data.categorie.present ? data.categorie.value : this.categorie,
      auteur: data.auteur.present ? data.auteur.value : this.auteur,
      urlAudio: data.urlAudio.present ? data.urlAudio.value : this.urlAudio,
      duree: data.duree.present ? data.duree.value : this.duree,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      partitionUrl: data.partitionUrl.present
          ? data.partitionUrl.value
          : this.partitionUrl,
      isCached: data.isCached.present ? data.isCached.value : this.isCached,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChantsTableData(')
          ..write('id: $id, ')
          ..write('titre: $titre, ')
          ..write('categorie: $categorie, ')
          ..write('auteur: $auteur, ')
          ..write('urlAudio: $urlAudio, ')
          ..write('duree: $duree, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('lyrics: $lyrics, ')
          ..write('partitionUrl: $partitionUrl, ')
          ..write('isCached: $isCached, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, titre, categorie, auteur, urlAudio, duree,
      createdAt, type, lyrics, partitionUrl, isCached, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChantsTableData &&
          other.id == this.id &&
          other.titre == this.titre &&
          other.categorie == this.categorie &&
          other.auteur == this.auteur &&
          other.urlAudio == this.urlAudio &&
          other.duree == this.duree &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.lyrics == this.lyrics &&
          other.partitionUrl == this.partitionUrl &&
          other.isCached == this.isCached &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class ChantsTableCompanion extends UpdateCompanion<ChantsTableData> {
  final Value<String> id;
  final Value<String> titre;
  final Value<String> categorie;
  final Value<String> auteur;
  final Value<String> urlAudio;
  final Value<int> duree;
  final Value<DateTime> createdAt;
  final Value<String> type;
  final Value<String?> lyrics;
  final Value<String?> partitionUrl;
  final Value<bool> isCached;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const ChantsTableCompanion({
    this.id = const Value.absent(),
    this.titre = const Value.absent(),
    this.categorie = const Value.absent(),
    this.auteur = const Value.absent(),
    this.urlAudio = const Value.absent(),
    this.duree = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.partitionUrl = const Value.absent(),
    this.isCached = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChantsTableCompanion.insert({
    required String id,
    required String titre,
    required String categorie,
    required String auteur,
    required String urlAudio,
    required int duree,
    required DateTime createdAt,
    this.type = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.partitionUrl = const Value.absent(),
    this.isCached = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        titre = Value(titre),
        categorie = Value(categorie),
        auteur = Value(auteur),
        urlAudio = Value(urlAudio),
        duree = Value(duree),
        createdAt = Value(createdAt);
  static Insertable<ChantsTableData> custom({
    Expression<String>? id,
    Expression<String>? titre,
    Expression<String>? categorie,
    Expression<String>? auteur,
    Expression<String>? urlAudio,
    Expression<int>? duree,
    Expression<DateTime>? createdAt,
    Expression<String>? type,
    Expression<String>? lyrics,
    Expression<String>? partitionUrl,
    Expression<bool>? isCached,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titre != null) 'titre': titre,
      if (categorie != null) 'categorie': categorie,
      if (auteur != null) 'auteur': auteur,
      if (urlAudio != null) 'url_audio': urlAudio,
      if (duree != null) 'duree': duree,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (lyrics != null) 'lyrics': lyrics,
      if (partitionUrl != null) 'partition_url': partitionUrl,
      if (isCached != null) 'is_cached': isCached,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChantsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? titre,
      Value<String>? categorie,
      Value<String>? auteur,
      Value<String>? urlAudio,
      Value<int>? duree,
      Value<DateTime>? createdAt,
      Value<String>? type,
      Value<String?>? lyrics,
      Value<String?>? partitionUrl,
      Value<bool>? isCached,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return ChantsTableCompanion(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      categorie: categorie ?? this.categorie,
      auteur: auteur ?? this.auteur,
      urlAudio: urlAudio ?? this.urlAudio,
      duree: duree ?? this.duree,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      lyrics: lyrics ?? this.lyrics,
      partitionUrl: partitionUrl ?? this.partitionUrl,
      isCached: isCached ?? this.isCached,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titre.present) {
      map['titre'] = Variable<String>(titre.value);
    }
    if (categorie.present) {
      map['categorie'] = Variable<String>(categorie.value);
    }
    if (auteur.present) {
      map['auteur'] = Variable<String>(auteur.value);
    }
    if (urlAudio.present) {
      map['url_audio'] = Variable<String>(urlAudio.value);
    }
    if (duree.present) {
      map['duree'] = Variable<int>(duree.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (partitionUrl.present) {
      map['partition_url'] = Variable<String>(partitionUrl.value);
    }
    if (isCached.present) {
      map['is_cached'] = Variable<bool>(isCached.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChantsTableCompanion(')
          ..write('id: $id, ')
          ..write('titre: $titre, ')
          ..write('categorie: $categorie, ')
          ..write('auteur: $auteur, ')
          ..write('urlAudio: $urlAudio, ')
          ..write('duree: $duree, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('lyrics: $lyrics, ')
          ..write('partitionUrl: $partitionUrl, ')
          ..write('isCached: $isCached, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTableTable extends FavoritesTable
    with TableInfo<$FavoritesTableTable, FavoritesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chantIdMeta =
      const VerificationMeta('chantId');
  @override
  late final GeneratedColumn<String> chantId = GeneratedColumn<String>(
      'chant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, chantId, createdAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites_table';
  @override
  VerificationContext validateIntegrity(Insertable<FavoritesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('chant_id')) {
      context.handle(_chantIdMeta,
          chantId.isAcceptableOrUnknown(data['chant_id']!, _chantIdMeta));
    } else if (isInserting) {
      context.missing(_chantIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoritesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      chantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chant_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $FavoritesTableTable createAlias(String alias) {
    return $FavoritesTableTable(attachedDatabase, alias);
  }
}

class FavoritesTableData extends DataClass
    implements Insertable<FavoritesTableData> {
  final String id;
  final String userId;
  final String chantId;
  final DateTime createdAt;
  final bool isSynced;
  const FavoritesTableData(
      {required this.id,
      required this.userId,
      required this.chantId,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['chant_id'] = Variable<String>(chantId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  FavoritesTableCompanion toCompanion(bool nullToAbsent) {
    return FavoritesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      chantId: Value(chantId),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory FavoritesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      chantId: serializer.fromJson<String>(json['chantId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'chantId': serializer.toJson<String>(chantId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  FavoritesTableData copyWith(
          {String? id,
          String? userId,
          String? chantId,
          DateTime? createdAt,
          bool? isSynced}) =>
      FavoritesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        chantId: chantId ?? this.chantId,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  FavoritesTableData copyWithCompanion(FavoritesTableCompanion data) {
    return FavoritesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      chantId: data.chantId.present ? data.chantId.value : this.chantId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('chantId: $chantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, chantId, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.chantId == this.chantId &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class FavoritesTableCompanion extends UpdateCompanion<FavoritesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> chantId;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const FavoritesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.chantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesTableCompanion.insert({
    required String id,
    required String userId,
    required String chantId,
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        chantId = Value(chantId),
        createdAt = Value(createdAt);
  static Insertable<FavoritesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? chantId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (chantId != null) 'chant_id': chantId,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? chantId,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return FavoritesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chantId: chantId ?? this.chantId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (chantId.present) {
      map['chant_id'] = Variable<String>(chantId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('chantId: $chantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTableTable extends PlaylistsTable
    with TableInfo<$PlaylistsTableTable, PlaylistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, description, createdAt, updatedAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists_table';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $PlaylistsTableTable createAlias(String alias) {
    return $PlaylistsTableTable(attachedDatabase, alias);
  }
}

class PlaylistsTableData extends DataClass
    implements Insertable<PlaylistsTableData> {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  const PlaylistsTableData(
      {required this.id,
      required this.userId,
      required this.name,
      this.description,
      required this.createdAt,
      required this.updatedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  PlaylistsTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory PlaylistsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  PlaylistsTableData copyWith(
          {String? id,
          String? userId,
          String? name,
          Value<String?> description = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isSynced}) =>
      PlaylistsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  PlaylistsTableData copyWithCompanion(PlaylistsTableCompanion data) {
    return PlaylistsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, name, description, createdAt, updatedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class PlaylistsTableCompanion extends UpdateCompanion<PlaylistsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const PlaylistsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsTableCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PlaylistsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return PlaylistsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistChantsTableTable extends PlaylistChantsTable
    with TableInfo<$PlaylistChantsTableTable, PlaylistChantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistChantsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chantIdMeta =
      const VerificationMeta('chantId');
  @override
  late final GeneratedColumn<String> chantId = GeneratedColumn<String>(
      'chant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, chantId, position, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_chants_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlaylistChantsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('chant_id')) {
      context.handle(_chantIdMeta,
          chantId.isAcceptableOrUnknown(data['chant_id']!, _chantIdMeta));
    } else if (isInserting) {
      context.missing(_chantIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistChantsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistChantsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      chantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chant_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $PlaylistChantsTableTable createAlias(String alias) {
    return $PlaylistChantsTableTable(attachedDatabase, alias);
  }
}

class PlaylistChantsTableData extends DataClass
    implements Insertable<PlaylistChantsTableData> {
  final String id;
  final String playlistId;
  final String chantId;
  final int position;
  final DateTime addedAt;
  const PlaylistChantsTableData(
      {required this.id,
      required this.playlistId,
      required this.chantId,
      required this.position,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['chant_id'] = Variable<String>(chantId);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistChantsTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistChantsTableCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      chantId: Value(chantId),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistChantsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistChantsTableData(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      chantId: serializer.fromJson<String>(json['chantId']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'chantId': serializer.toJson<String>(chantId),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistChantsTableData copyWith(
          {String? id,
          String? playlistId,
          String? chantId,
          int? position,
          DateTime? addedAt}) =>
      PlaylistChantsTableData(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        chantId: chantId ?? this.chantId,
        position: position ?? this.position,
        addedAt: addedAt ?? this.addedAt,
      );
  PlaylistChantsTableData copyWithCompanion(PlaylistChantsTableCompanion data) {
    return PlaylistChantsTableData(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      chantId: data.chantId.present ? data.chantId.value : this.chantId,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistChantsTableData(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('chantId: $chantId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, chantId, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistChantsTableData &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.chantId == this.chantId &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistChantsTableCompanion
    extends UpdateCompanion<PlaylistChantsTableData> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> chantId;
  final Value<int> position;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const PlaylistChantsTableCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.chantId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistChantsTableCompanion.insert({
    required String id,
    required String playlistId,
    required String chantId,
    required int position,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        playlistId = Value(playlistId),
        chantId = Value(chantId),
        position = Value(position),
        addedAt = Value(addedAt);
  static Insertable<PlaylistChantsTableData> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? chantId,
    Expression<int>? position,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (chantId != null) 'chant_id': chantId,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistChantsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? playlistId,
      Value<String>? chantId,
      Value<int>? position,
      Value<DateTime>? addedAt,
      Value<int>? rowid}) {
    return PlaylistChantsTableCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      chantId: chantId ?? this.chantId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (chantId.present) {
      map['chant_id'] = Variable<String>(chantId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistChantsTableCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('chantId: $chantId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningHistoryTableTable extends ListeningHistoryTable
    with TableInfo<$ListeningHistoryTableTable, ListeningHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chantIdMeta =
      const VerificationMeta('chantId');
  @override
  late final GeneratedColumn<String> chantId = GeneratedColumn<String>(
      'chant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listenedAtMeta =
      const VerificationMeta('listenedAt');
  @override
  late final GeneratedColumn<DateTime> listenedAt = GeneratedColumn<DateTime>(
      'listened_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, chantId, listenedAt, duration, completed, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_history_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ListeningHistoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('chant_id')) {
      context.handle(_chantIdMeta,
          chantId.isAcceptableOrUnknown(data['chant_id']!, _chantIdMeta));
    } else if (isInserting) {
      context.missing(_chantIdMeta);
    }
    if (data.containsKey('listened_at')) {
      context.handle(
          _listenedAtMeta,
          listenedAt.isAcceptableOrUnknown(
              data['listened_at']!, _listenedAtMeta));
    } else if (isInserting) {
      context.missing(_listenedAtMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningHistoryTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningHistoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      chantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chant_id'])!,
      listenedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}listened_at'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $ListeningHistoryTableTable createAlias(String alias) {
    return $ListeningHistoryTableTable(attachedDatabase, alias);
  }
}

class ListeningHistoryTableData extends DataClass
    implements Insertable<ListeningHistoryTableData> {
  final String id;
  final String userId;
  final String chantId;
  final DateTime listenedAt;
  final int duration;
  final bool completed;
  final bool isSynced;
  const ListeningHistoryTableData(
      {required this.id,
      required this.userId,
      required this.chantId,
      required this.listenedAt,
      required this.duration,
      required this.completed,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['chant_id'] = Variable<String>(chantId);
    map['listened_at'] = Variable<DateTime>(listenedAt);
    map['duration'] = Variable<int>(duration);
    map['completed'] = Variable<bool>(completed);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ListeningHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return ListeningHistoryTableCompanion(
      id: Value(id),
      userId: Value(userId),
      chantId: Value(chantId),
      listenedAt: Value(listenedAt),
      duration: Value(duration),
      completed: Value(completed),
      isSynced: Value(isSynced),
    );
  }

  factory ListeningHistoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningHistoryTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      chantId: serializer.fromJson<String>(json['chantId']),
      listenedAt: serializer.fromJson<DateTime>(json['listenedAt']),
      duration: serializer.fromJson<int>(json['duration']),
      completed: serializer.fromJson<bool>(json['completed']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'chantId': serializer.toJson<String>(chantId),
      'listenedAt': serializer.toJson<DateTime>(listenedAt),
      'duration': serializer.toJson<int>(duration),
      'completed': serializer.toJson<bool>(completed),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ListeningHistoryTableData copyWith(
          {String? id,
          String? userId,
          String? chantId,
          DateTime? listenedAt,
          int? duration,
          bool? completed,
          bool? isSynced}) =>
      ListeningHistoryTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        chantId: chantId ?? this.chantId,
        listenedAt: listenedAt ?? this.listenedAt,
        duration: duration ?? this.duration,
        completed: completed ?? this.completed,
        isSynced: isSynced ?? this.isSynced,
      );
  ListeningHistoryTableData copyWithCompanion(
      ListeningHistoryTableCompanion data) {
    return ListeningHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      chantId: data.chantId.present ? data.chantId.value : this.chantId,
      listenedAt:
          data.listenedAt.present ? data.listenedAt.value : this.listenedAt,
      duration: data.duration.present ? data.duration.value : this.duration,
      completed: data.completed.present ? data.completed.value : this.completed,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningHistoryTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('chantId: $chantId, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('duration: $duration, ')
          ..write('completed: $completed, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, chantId, listenedAt, duration, completed, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningHistoryTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.chantId == this.chantId &&
          other.listenedAt == this.listenedAt &&
          other.duration == this.duration &&
          other.completed == this.completed &&
          other.isSynced == this.isSynced);
}

class ListeningHistoryTableCompanion
    extends UpdateCompanion<ListeningHistoryTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> chantId;
  final Value<DateTime> listenedAt;
  final Value<int> duration;
  final Value<bool> completed;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ListeningHistoryTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.chantId = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.completed = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningHistoryTableCompanion.insert({
    required String id,
    required String userId,
    required String chantId,
    required DateTime listenedAt,
    required int duration,
    this.completed = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        chantId = Value(chantId),
        listenedAt = Value(listenedAt),
        duration = Value(duration);
  static Insertable<ListeningHistoryTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? chantId,
    Expression<DateTime>? listenedAt,
    Expression<int>? duration,
    Expression<bool>? completed,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (chantId != null) 'chant_id': chantId,
      if (listenedAt != null) 'listened_at': listenedAt,
      if (duration != null) 'duration': duration,
      if (completed != null) 'completed': completed,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningHistoryTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? chantId,
      Value<DateTime>? listenedAt,
      Value<int>? duration,
      Value<bool>? completed,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return ListeningHistoryTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chantId: chantId ?? this.chantId,
      listenedAt: listenedAt ?? this.listenedAt,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (chantId.present) {
      map['chant_id'] = Variable<String>(chantId.value);
    }
    if (listenedAt.present) {
      map['listened_at'] = Variable<DateTime>(listenedAt.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('chantId: $chantId, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('duration: $duration, ')
          ..write('completed: $completed, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadedChantsTableTable extends DownloadedChantsTable
    with TableInfo<$DownloadedChantsTableTable, DownloadedChantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedChantsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chantIdMeta =
      const VerificationMeta('chantId');
  @override
  late final GeneratedColumn<String> chantId = GeneratedColumn<String>(
      'chant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, chantId, localPath, fileSize, downloadedAt, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_chants_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<DownloadedChantsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chant_id')) {
      context.handle(_chantIdMeta,
          chantId.isAcceptableOrUnknown(data['chant_id']!, _chantIdMeta));
    } else if (isInserting) {
      context.missing(_chantIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadedChantsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedChantsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      chantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chant_id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $DownloadedChantsTableTable createAlias(String alias) {
    return $DownloadedChantsTableTable(attachedDatabase, alias);
  }
}

class DownloadedChantsTableData extends DataClass
    implements Insertable<DownloadedChantsTableData> {
  final String id;
  final String chantId;
  final String localPath;
  final int fileSize;
  final DateTime downloadedAt;
  final String status;
  const DownloadedChantsTableData(
      {required this.id,
      required this.chantId,
      required this.localPath,
      required this.fileSize,
      required this.downloadedAt,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chant_id'] = Variable<String>(chantId);
    map['local_path'] = Variable<String>(localPath);
    map['file_size'] = Variable<int>(fileSize);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  DownloadedChantsTableCompanion toCompanion(bool nullToAbsent) {
    return DownloadedChantsTableCompanion(
      id: Value(id),
      chantId: Value(chantId),
      localPath: Value(localPath),
      fileSize: Value(fileSize),
      downloadedAt: Value(downloadedAt),
      status: Value(status),
    );
  }

  factory DownloadedChantsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedChantsTableData(
      id: serializer.fromJson<String>(json['id']),
      chantId: serializer.fromJson<String>(json['chantId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chantId': serializer.toJson<String>(chantId),
      'localPath': serializer.toJson<String>(localPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  DownloadedChantsTableData copyWith(
          {String? id,
          String? chantId,
          String? localPath,
          int? fileSize,
          DateTime? downloadedAt,
          String? status}) =>
      DownloadedChantsTableData(
        id: id ?? this.id,
        chantId: chantId ?? this.chantId,
        localPath: localPath ?? this.localPath,
        fileSize: fileSize ?? this.fileSize,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        status: status ?? this.status,
      );
  DownloadedChantsTableData copyWithCompanion(
      DownloadedChantsTableCompanion data) {
    return DownloadedChantsTableData(
      id: data.id.present ? data.id.value : this.id,
      chantId: data.chantId.present ? data.chantId.value : this.chantId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedChantsTableData(')
          ..write('id: $id, ')
          ..write('chantId: $chantId, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, chantId, localPath, fileSize, downloadedAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedChantsTableData &&
          other.id == this.id &&
          other.chantId == this.chantId &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.downloadedAt == this.downloadedAt &&
          other.status == this.status);
}

class DownloadedChantsTableCompanion
    extends UpdateCompanion<DownloadedChantsTableData> {
  final Value<String> id;
  final Value<String> chantId;
  final Value<String> localPath;
  final Value<int> fileSize;
  final Value<DateTime> downloadedAt;
  final Value<String> status;
  final Value<int> rowid;
  const DownloadedChantsTableCompanion({
    this.id = const Value.absent(),
    this.chantId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedChantsTableCompanion.insert({
    required String id,
    required String chantId,
    required String localPath,
    required int fileSize,
    required DateTime downloadedAt,
    required String status,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        chantId = Value(chantId),
        localPath = Value(localPath),
        fileSize = Value(fileSize),
        downloadedAt = Value(downloadedAt),
        status = Value(status);
  static Insertable<DownloadedChantsTableData> custom({
    Expression<String>? id,
    Expression<String>? chantId,
    Expression<String>? localPath,
    Expression<int>? fileSize,
    Expression<DateTime>? downloadedAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chantId != null) 'chant_id': chantId,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedChantsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? chantId,
      Value<String>? localPath,
      Value<int>? fileSize,
      Value<DateTime>? downloadedAt,
      Value<String>? status,
      Value<int>? rowid}) {
    return DownloadedChantsTableCompanion(
      id: id ?? this.id,
      chantId: chantId ?? this.chantId,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chantId.present) {
      map['chant_id'] = Variable<String>(chantId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedChantsTableCompanion(')
          ..write('id: $id, ')
          ..write('chantId: $chantId, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChantsTableTable chantsTable = $ChantsTableTable(this);
  late final $FavoritesTableTable favoritesTable = $FavoritesTableTable(this);
  late final $PlaylistsTableTable playlistsTable = $PlaylistsTableTable(this);
  late final $PlaylistChantsTableTable playlistChantsTable =
      $PlaylistChantsTableTable(this);
  late final $ListeningHistoryTableTable listeningHistoryTable =
      $ListeningHistoryTableTable(this);
  late final $DownloadedChantsTableTable downloadedChantsTable =
      $DownloadedChantsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        chantsTable,
        favoritesTable,
        playlistsTable,
        playlistChantsTable,
        listeningHistoryTable,
        downloadedChantsTable
      ];
}

typedef $$ChantsTableTableCreateCompanionBuilder = ChantsTableCompanion
    Function({
  required String id,
  required String titre,
  required String categorie,
  required String auteur,
  required String urlAudio,
  required int duree,
  required DateTime createdAt,
  Value<String> type,
  Value<String?> lyrics,
  Value<String?> partitionUrl,
  Value<bool> isCached,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$ChantsTableTableUpdateCompanionBuilder = ChantsTableCompanion
    Function({
  Value<String> id,
  Value<String> titre,
  Value<String> categorie,
  Value<String> auteur,
  Value<String> urlAudio,
  Value<int> duree,
  Value<DateTime> createdAt,
  Value<String> type,
  Value<String?> lyrics,
  Value<String?> partitionUrl,
  Value<bool> isCached,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$ChantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChantsTableTable> {
  $$ChantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get auteur => $composableBuilder(
      column: $table.auteur, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get urlAudio => $composableBuilder(
      column: $table.urlAudio, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duree => $composableBuilder(
      column: $table.duree, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partitionUrl => $composableBuilder(
      column: $table.partitionUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCached => $composableBuilder(
      column: $table.isCached, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$ChantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChantsTableTable> {
  $$ChantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get auteur => $composableBuilder(
      column: $table.auteur, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get urlAudio => $composableBuilder(
      column: $table.urlAudio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duree => $composableBuilder(
      column: $table.duree, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partitionUrl => $composableBuilder(
      column: $table.partitionUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCached => $composableBuilder(
      column: $table.isCached, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ChantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChantsTableTable> {
  $$ChantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titre =>
      $composableBuilder(column: $table.titre, builder: (column) => column);

  GeneratedColumn<String> get categorie =>
      $composableBuilder(column: $table.categorie, builder: (column) => column);

  GeneratedColumn<String> get auteur =>
      $composableBuilder(column: $table.auteur, builder: (column) => column);

  GeneratedColumn<String> get urlAudio =>
      $composableBuilder(column: $table.urlAudio, builder: (column) => column);

  GeneratedColumn<int> get duree =>
      $composableBuilder(column: $table.duree, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumn<String> get partitionUrl => $composableBuilder(
      column: $table.partitionUrl, builder: (column) => column);

  GeneratedColumn<bool> get isCached =>
      $composableBuilder(column: $table.isCached, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$ChantsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChantsTableTable,
    ChantsTableData,
    $$ChantsTableTableFilterComposer,
    $$ChantsTableTableOrderingComposer,
    $$ChantsTableTableAnnotationComposer,
    $$ChantsTableTableCreateCompanionBuilder,
    $$ChantsTableTableUpdateCompanionBuilder,
    (
      ChantsTableData,
      BaseReferences<_$AppDatabase, $ChantsTableTable, ChantsTableData>
    ),
    ChantsTableData,
    PrefetchHooks Function()> {
  $$ChantsTableTableTableManager(_$AppDatabase db, $ChantsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChantsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChantsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChantsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> titre = const Value.absent(),
            Value<String> categorie = const Value.absent(),
            Value<String> auteur = const Value.absent(),
            Value<String> urlAudio = const Value.absent(),
            Value<int> duree = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> partitionUrl = const Value.absent(),
            Value<bool> isCached = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChantsTableCompanion(
            id: id,
            titre: titre,
            categorie: categorie,
            auteur: auteur,
            urlAudio: urlAudio,
            duree: duree,
            createdAt: createdAt,
            type: type,
            lyrics: lyrics,
            partitionUrl: partitionUrl,
            isCached: isCached,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String titre,
            required String categorie,
            required String auteur,
            required String urlAudio,
            required int duree,
            required DateTime createdAt,
            Value<String> type = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> partitionUrl = const Value.absent(),
            Value<bool> isCached = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChantsTableCompanion.insert(
            id: id,
            titre: titre,
            categorie: categorie,
            auteur: auteur,
            urlAudio: urlAudio,
            duree: duree,
            createdAt: createdAt,
            type: type,
            lyrics: lyrics,
            partitionUrl: partitionUrl,
            isCached: isCached,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChantsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChantsTableTable,
    ChantsTableData,
    $$ChantsTableTableFilterComposer,
    $$ChantsTableTableOrderingComposer,
    $$ChantsTableTableAnnotationComposer,
    $$ChantsTableTableCreateCompanionBuilder,
    $$ChantsTableTableUpdateCompanionBuilder,
    (
      ChantsTableData,
      BaseReferences<_$AppDatabase, $ChantsTableTable, ChantsTableData>
    ),
    ChantsTableData,
    PrefetchHooks Function()>;
typedef $$FavoritesTableTableCreateCompanionBuilder = FavoritesTableCompanion
    Function({
  required String id,
  required String userId,
  required String chantId,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$FavoritesTableTableUpdateCompanionBuilder = FavoritesTableCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> chantId,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$FavoritesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$FavoritesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$FavoritesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get chantId =>
      $composableBuilder(column: $table.chantId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$FavoritesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoritesTableTable,
    FavoritesTableData,
    $$FavoritesTableTableFilterComposer,
    $$FavoritesTableTableOrderingComposer,
    $$FavoritesTableTableAnnotationComposer,
    $$FavoritesTableTableCreateCompanionBuilder,
    $$FavoritesTableTableUpdateCompanionBuilder,
    (
      FavoritesTableData,
      BaseReferences<_$AppDatabase, $FavoritesTableTable, FavoritesTableData>
    ),
    FavoritesTableData,
    PrefetchHooks Function()> {
  $$FavoritesTableTableTableManager(
      _$AppDatabase db, $FavoritesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> chantId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoritesTableCompanion(
            id: id,
            userId: userId,
            chantId: chantId,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String chantId,
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoritesTableCompanion.insert(
            id: id,
            userId: userId,
            chantId: chantId,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoritesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoritesTableTable,
    FavoritesTableData,
    $$FavoritesTableTableFilterComposer,
    $$FavoritesTableTableOrderingComposer,
    $$FavoritesTableTableAnnotationComposer,
    $$FavoritesTableTableCreateCompanionBuilder,
    $$FavoritesTableTableUpdateCompanionBuilder,
    (
      FavoritesTableData,
      BaseReferences<_$AppDatabase, $FavoritesTableTable, FavoritesTableData>
    ),
    FavoritesTableData,
    PrefetchHooks Function()>;
typedef $$PlaylistsTableTableCreateCompanionBuilder = PlaylistsTableCompanion
    Function({
  required String id,
  required String userId,
  required String name,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$PlaylistsTableTableUpdateCompanionBuilder = PlaylistsTableCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$PlaylistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$PlaylistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$PlaylistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$PlaylistsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistsTableTable,
    PlaylistsTableData,
    $$PlaylistsTableTableFilterComposer,
    $$PlaylistsTableTableOrderingComposer,
    $$PlaylistsTableTableAnnotationComposer,
    $$PlaylistsTableTableCreateCompanionBuilder,
    $$PlaylistsTableTableUpdateCompanionBuilder,
    (
      PlaylistsTableData,
      BaseReferences<_$AppDatabase, $PlaylistsTableTable, PlaylistsTableData>
    ),
    PlaylistsTableData,
    PrefetchHooks Function()> {
  $$PlaylistsTableTableTableManager(
      _$AppDatabase db, $PlaylistsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsTableCompanion(
            id: id,
            userId: userId,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            Value<String?> description = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsTableCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaylistsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistsTableTable,
    PlaylistsTableData,
    $$PlaylistsTableTableFilterComposer,
    $$PlaylistsTableTableOrderingComposer,
    $$PlaylistsTableTableAnnotationComposer,
    $$PlaylistsTableTableCreateCompanionBuilder,
    $$PlaylistsTableTableUpdateCompanionBuilder,
    (
      PlaylistsTableData,
      BaseReferences<_$AppDatabase, $PlaylistsTableTable, PlaylistsTableData>
    ),
    PlaylistsTableData,
    PrefetchHooks Function()>;
typedef $$PlaylistChantsTableTableCreateCompanionBuilder
    = PlaylistChantsTableCompanion Function({
  required String id,
  required String playlistId,
  required String chantId,
  required int position,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$PlaylistChantsTableTableUpdateCompanionBuilder
    = PlaylistChantsTableCompanion Function({
  Value<String> id,
  Value<String> playlistId,
  Value<String> chantId,
  Value<int> position,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$PlaylistChantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistChantsTableTable> {
  $$PlaylistChantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$PlaylistChantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistChantsTableTable> {
  $$PlaylistChantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlaylistChantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistChantsTableTable> {
  $$PlaylistChantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<String> get chantId =>
      $composableBuilder(column: $table.chantId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$PlaylistChantsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistChantsTableTable,
    PlaylistChantsTableData,
    $$PlaylistChantsTableTableFilterComposer,
    $$PlaylistChantsTableTableOrderingComposer,
    $$PlaylistChantsTableTableAnnotationComposer,
    $$PlaylistChantsTableTableCreateCompanionBuilder,
    $$PlaylistChantsTableTableUpdateCompanionBuilder,
    (
      PlaylistChantsTableData,
      BaseReferences<_$AppDatabase, $PlaylistChantsTableTable,
          PlaylistChantsTableData>
    ),
    PlaylistChantsTableData,
    PrefetchHooks Function()> {
  $$PlaylistChantsTableTableTableManager(
      _$AppDatabase db, $PlaylistChantsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistChantsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistChantsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistChantsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> chantId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistChantsTableCompanion(
            id: id,
            playlistId: playlistId,
            chantId: chantId,
            position: position,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String playlistId,
            required String chantId,
            required int position,
            required DateTime addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistChantsTableCompanion.insert(
            id: id,
            playlistId: playlistId,
            chantId: chantId,
            position: position,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaylistChantsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistChantsTableTable,
    PlaylistChantsTableData,
    $$PlaylistChantsTableTableFilterComposer,
    $$PlaylistChantsTableTableOrderingComposer,
    $$PlaylistChantsTableTableAnnotationComposer,
    $$PlaylistChantsTableTableCreateCompanionBuilder,
    $$PlaylistChantsTableTableUpdateCompanionBuilder,
    (
      PlaylistChantsTableData,
      BaseReferences<_$AppDatabase, $PlaylistChantsTableTable,
          PlaylistChantsTableData>
    ),
    PlaylistChantsTableData,
    PrefetchHooks Function()>;
typedef $$ListeningHistoryTableTableCreateCompanionBuilder
    = ListeningHistoryTableCompanion Function({
  required String id,
  required String userId,
  required String chantId,
  required DateTime listenedAt,
  required int duration,
  Value<bool> completed,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$ListeningHistoryTableTableUpdateCompanionBuilder
    = ListeningHistoryTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> chantId,
  Value<DateTime> listenedAt,
  Value<int> duration,
  Value<bool> completed,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$ListeningHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTableTable> {
  $$ListeningHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$ListeningHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTableTable> {
  $$ListeningHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$ListeningHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTableTable> {
  $$ListeningHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get chantId =>
      $composableBuilder(column: $table.chantId, builder: (column) => column);

  GeneratedColumn<DateTime> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ListeningHistoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListeningHistoryTableTable,
    ListeningHistoryTableData,
    $$ListeningHistoryTableTableFilterComposer,
    $$ListeningHistoryTableTableOrderingComposer,
    $$ListeningHistoryTableTableAnnotationComposer,
    $$ListeningHistoryTableTableCreateCompanionBuilder,
    $$ListeningHistoryTableTableUpdateCompanionBuilder,
    (
      ListeningHistoryTableData,
      BaseReferences<_$AppDatabase, $ListeningHistoryTableTable,
          ListeningHistoryTableData>
    ),
    ListeningHistoryTableData,
    PrefetchHooks Function()> {
  $$ListeningHistoryTableTableTableManager(
      _$AppDatabase db, $ListeningHistoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningHistoryTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningHistoryTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningHistoryTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> chantId = const Value.absent(),
            Value<DateTime> listenedAt = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ListeningHistoryTableCompanion(
            id: id,
            userId: userId,
            chantId: chantId,
            listenedAt: listenedAt,
            duration: duration,
            completed: completed,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String chantId,
            required DateTime listenedAt,
            required int duration,
            Value<bool> completed = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ListeningHistoryTableCompanion.insert(
            id: id,
            userId: userId,
            chantId: chantId,
            listenedAt: listenedAt,
            duration: duration,
            completed: completed,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ListeningHistoryTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ListeningHistoryTableTable,
        ListeningHistoryTableData,
        $$ListeningHistoryTableTableFilterComposer,
        $$ListeningHistoryTableTableOrderingComposer,
        $$ListeningHistoryTableTableAnnotationComposer,
        $$ListeningHistoryTableTableCreateCompanionBuilder,
        $$ListeningHistoryTableTableUpdateCompanionBuilder,
        (
          ListeningHistoryTableData,
          BaseReferences<_$AppDatabase, $ListeningHistoryTableTable,
              ListeningHistoryTableData>
        ),
        ListeningHistoryTableData,
        PrefetchHooks Function()>;
typedef $$DownloadedChantsTableTableCreateCompanionBuilder
    = DownloadedChantsTableCompanion Function({
  required String id,
  required String chantId,
  required String localPath,
  required int fileSize,
  required DateTime downloadedAt,
  required String status,
  Value<int> rowid,
});
typedef $$DownloadedChantsTableTableUpdateCompanionBuilder
    = DownloadedChantsTableCompanion Function({
  Value<String> id,
  Value<String> chantId,
  Value<String> localPath,
  Value<int> fileSize,
  Value<DateTime> downloadedAt,
  Value<String> status,
  Value<int> rowid,
});

class $$DownloadedChantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedChantsTableTable> {
  $$DownloadedChantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$DownloadedChantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedChantsTableTable> {
  $$DownloadedChantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chantId => $composableBuilder(
      column: $table.chantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$DownloadedChantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedChantsTableTable> {
  $$DownloadedChantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chantId =>
      $composableBuilder(column: $table.chantId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$DownloadedChantsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadedChantsTableTable,
    DownloadedChantsTableData,
    $$DownloadedChantsTableTableFilterComposer,
    $$DownloadedChantsTableTableOrderingComposer,
    $$DownloadedChantsTableTableAnnotationComposer,
    $$DownloadedChantsTableTableCreateCompanionBuilder,
    $$DownloadedChantsTableTableUpdateCompanionBuilder,
    (
      DownloadedChantsTableData,
      BaseReferences<_$AppDatabase, $DownloadedChantsTableTable,
          DownloadedChantsTableData>
    ),
    DownloadedChantsTableData,
    PrefetchHooks Function()> {
  $$DownloadedChantsTableTableTableManager(
      _$AppDatabase db, $DownloadedChantsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedChantsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedChantsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedChantsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> chantId = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadedChantsTableCompanion(
            id: id,
            chantId: chantId,
            localPath: localPath,
            fileSize: fileSize,
            downloadedAt: downloadedAt,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String chantId,
            required String localPath,
            required int fileSize,
            required DateTime downloadedAt,
            required String status,
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadedChantsTableCompanion.insert(
            id: id,
            chantId: chantId,
            localPath: localPath,
            fileSize: fileSize,
            downloadedAt: downloadedAt,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadedChantsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DownloadedChantsTableTable,
        DownloadedChantsTableData,
        $$DownloadedChantsTableTableFilterComposer,
        $$DownloadedChantsTableTableOrderingComposer,
        $$DownloadedChantsTableTableAnnotationComposer,
        $$DownloadedChantsTableTableCreateCompanionBuilder,
        $$DownloadedChantsTableTableUpdateCompanionBuilder,
        (
          DownloadedChantsTableData,
          BaseReferences<_$AppDatabase, $DownloadedChantsTableTable,
              DownloadedChantsTableData>
        ),
        DownloadedChantsTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChantsTableTableTableManager get chantsTable =>
      $$ChantsTableTableTableManager(_db, _db.chantsTable);
  $$FavoritesTableTableTableManager get favoritesTable =>
      $$FavoritesTableTableTableManager(_db, _db.favoritesTable);
  $$PlaylistsTableTableTableManager get playlistsTable =>
      $$PlaylistsTableTableTableManager(_db, _db.playlistsTable);
  $$PlaylistChantsTableTableTableManager get playlistChantsTable =>
      $$PlaylistChantsTableTableTableManager(_db, _db.playlistChantsTable);
  $$ListeningHistoryTableTableTableManager get listeningHistoryTable =>
      $$ListeningHistoryTableTableTableManager(_db, _db.listeningHistoryTable);
  $$DownloadedChantsTableTableTableManager get downloadedChantsTable =>
      $$DownloadedChantsTableTableTableManager(_db, _db.downloadedChantsTable);
}
